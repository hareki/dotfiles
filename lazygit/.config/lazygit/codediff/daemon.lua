-- Persistent render daemon, started by client.sh as:
--   nvim --clean --headless -c "luafile daemon.lua"
-- (-l would exit after running the script; -c keeps the server alive.)
--
-- Renders arrive over a plain line protocol on a unix socket -- see the pipe
-- section at the bottom.
--
-- Lifetime: exits when every lazygit process registered as its owner is gone
-- (polled every few seconds), so quitting lazygit (or the nvim :terminal hosting
-- it) leaves no orphaned daemon. Idle timeouts back that up, and a change to the
-- nvim binary, to the renderer's own sources or to anything bootstrap loads
-- (parsers, plugins, filetype rules) recycles the daemon on the next request.

local script = arg and arg[0] or debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(script, ':p:h')
package.path = dir .. '/?.lua;' .. package.path

local uv = vim.uv

-- The spawning render task's pty goes away right after we start; SIGHUP from
-- that teardown must not kill the daemon.
uv.new_signal():start('sighup', function() end)

-- Bootstrap owns the list of paths a render depends on, so the staleness check
-- reads that list rather than re-deriving it, and reads *all* of it: a
-- dependency added there cannot be one the fingerprint forgot. Sorted because
-- pairs order is not stable, and the fingerprint is compared against itself.
-- Guarded like the bootstrap call further down, because an error raised before
-- the lifetime guards are armed would strand an nvim holding the socket
-- forever; scripts_mtime() covers bootstrap.lua itself either way, so an
-- editing mistake there still recycles the daemon.
local ok_paths, bootstrap = pcall(require, 'lib.bootstrap')
local paths = ok_paths and bootstrap.paths or {}
local WATCHED_PATHS = vim.tbl_values(paths)
table.sort(WATCHED_PATHS)

-- The client owns the socket name and hands it down through the spawner's
-- environment. Deriving it a second time here would be the same cross-process
-- invariant spelled in two languages, kept in step by hand; without the handoff
-- there is nothing to serve, so this exits rather than guessing at a path no
-- client would be listening to.
local PIPE_PATH = vim.env.CODEDIFF_PIPE
if not PIPE_PATH or PIPE_PATH == '' then
  os.exit(1)
end
local IDLE_WITH_OWNER_MS = 60 * 60 * 1000
local IDLE_NO_OWNER_MS = 5 * 60 * 1000
-- Owners are registered on demand (a client walks its process tree only when
-- asked to), so an empty watch list also describes a live lazygit that has not
-- been asked yet. A short grace after the last request tells the two apart:
-- quitting lazygit still reaps the daemon within seconds, while a session whose
-- owner has not been registered yet keeps it alive by rendering at all.
local ORPHANED_GRACE_MS = 10 * 1000
-- An answer that asks for the owner costs the client a process tree walk, so
-- this long passes between two of them. A client that found none (a manual pipe
-- into the renderer, a lazygit reached through some wrapper) would find none
-- again, and one that named a live owner is only asked again for the sake of a
-- second lazygit (see want_owner).
local OWNER_ASK_INTERVAL_MS = 30 * 1000
local POLL_MS = 3000

-- Microseconds, not seconds: a whole-second resolution lets an edit that lands
-- in the same second as the snapshot go unnoticed for the daemon's lifetime.
local function mtime_of(path)
  local st = uv.fs_stat(path)
  if not st then
    return 0
  end
  return st.mtime.sec * 1000000 + math.floor((st.mtime.nsec or 0) / 1000)
end

-- Newest mtime across the renderer's own sources, so editing them recycles
-- the daemon on the next request instead of serving stale code.
local function scripts_mtime()
  local latest = 0
  for _, d in ipairs({ dir, dir .. '/lib' }) do
    for name, kind in vim.fs.dir(d) do
      if kind == 'file' then
        latest = math.max(latest, mtime_of(d .. '/' .. name))
      end
    end
  end
  return latest
end

-- Everything whose change must recycle the daemon, in one value: listing the
-- inputs once means a new one cannot be added to the snapshot but missed in the
-- comparison, which would silently never trigger a reload.
local function fingerprint()
  local parts = { mtime_of(vim.v.progpath), scripts_mtime() }
  for _, path in ipairs(WATCHED_PATHS) do
    parts[#parts + 1] = mtime_of(path)
  end
  return table.concat(parts, ':')
end

local generation = fingerprint()

local watched = {}
local saw_owner = false
local last_request = uv.now()
-- When a client last answered the owner question at all, and when one last
-- answered that it found none.
local owner_answered = -OWNER_ASK_INTERVAL_MS
local owner_declined = -OWNER_ASK_INTERVAL_MS

local pipe_ino = nil

-- os.exit skips nvim's own socket cleanup, so unlink here -- but only while the
-- path is still *ours*: it is shared by every daemon, and a successor may
-- already have bound its own at the same name.
local function shutdown(code)
  local st = pipe_ino and uv.fs_stat(PIPE_PATH)
  if st and st.ino == pipe_ino then
    pcall(os.remove, PIPE_PATH)
  end
  os.exit(code or 0)
end

local poll = assert(uv.new_timer())
poll:start(POLL_MS, POLL_MS, function()
  for pid in pairs(watched) do
    if not uv.kill(pid, 0) then
      watched[pid] = nil
    end
  end
  local idle = uv.now() - last_request
  if saw_owner and next(watched) == nil and idle > ORPHANED_GRACE_MS then
    shutdown()
  end
  if idle > (saw_owner and IDLE_WITH_OWNER_MS or IDLE_NO_OWNER_MS) then
    shutdown()
  end
end)

-- Bootstrapping happens only after the lifetime guards above are armed, and
-- behind a pcall: an error here (broken renderer source, a plugin dir being
-- updated underneath us) would otherwise abort the -c luafile, leaving a daemon
-- that answers nothing and never exits while every subsequent render spawns
-- another one.
local ok_boot, core = pcall(function()
  bootstrap.setup()
  return require('lib.core')
end)
if not ok_boot then
  shutdown(1)
end

-- Rendered-output cache: browsing commits in lazygit re-requests the same diff
-- every time the selection returns to it, and the expensive renders (large
-- commits) are exactly the ones worth never paying twice. Keyed by the full
-- input plus everything else that shapes the output; renders that consulted
-- the worktree are not cached, since the file on disk can change under an
-- unchanged diff. A daemon recycle (parser/plugin/source updates) drops the
-- cache with the process.
-- Sized so the byte ceiling below stays the binding constraint rather than this
-- count: a single file's diff renders to well under a megabyte, so 32 MB is
-- room for dozens, and a commit-sized render still leaves room for twenty.
-- Eviction is an O(n) scan, trivial at this size.
local CACHE_MAX = 24
-- Rendered ANSI runs ~5-8x its input (tinted rows pad out to the full width),
-- so a handful of large-commit renders can pin tens of MB for the daemon's
-- lifetime; the byte ceiling bounds memory where the entry count cannot.
local CACHE_MAX_BYTES = 32 * 1024 * 1024
local cache_entries, cache_count, cache_bytes, cache_tick = {}, 0, 0, 0

local function cache_get(key)
  local e = cache_entries[key]
  if not e then
    return nil
  end
  cache_tick = cache_tick + 1
  e.stamp = cache_tick
  return e.out
end

local function cache_put(key, out)
  if #out > CACHE_MAX_BYTES then
    return
  end
  local prev = cache_entries[key]
  if prev then
    cache_bytes = cache_bytes - #prev.out
  else
    cache_count = cache_count + 1
  end
  cache_tick = cache_tick + 1
  cache_entries[key] = { out = out, stamp = cache_tick }
  cache_bytes = cache_bytes + #out
  while cache_count > CACHE_MAX or cache_bytes > CACHE_MAX_BYTES do
    -- Never left unset: the loop only runs with at least two entries cached.
    local oldest_key --- @type string
    local oldest = math.huge
    for k, e in pairs(cache_entries) do
      if e.stamp < oldest then
        oldest_key, oldest = k, e.stamp
      end
    end
    cache_bytes = cache_bytes - #cache_entries[oldest_key].out
    cache_entries[oldest_key] = nil
    cache_count = cache_count - 1
  end
end

-- Whether this answer should ask the client for an owner pid. A request says
-- nothing about which lazygit sent it, so a second lazygit sharing the daemon
-- looks exactly like the one already watched: asking again once per interval is
-- what registers it, where asking only while watching nobody let the first
-- owner's exit take the daemon down under a session still using it. Inside the
-- interval the only thing worth a walk is an owner that has died since, which
-- is an empty watch list that a client's "found none" does not explain.
--
-- The throttle starts from a client's *answer*, not from the ask: a client that
-- lazygit terminated between its render and its answer must not leave the
-- daemon unowned for the whole interval, so the next render simply asks again.
local function want_owner()
  local now = uv.now()
  if now - owner_answered >= OWNER_ASK_INTERVAL_MS then
    return true
  end
  return next(watched) == nil and now - owner_declined >= OWNER_ASK_INTERVAL_MS
end

-- The output path is derived from the client's mktemp'd input path rather than
-- made by a second mktemp of its own, so this is the one file the daemon
-- creates: O_EXCL after an unlink, never O_TRUNC, means a name somebody else
-- planted in between (a symlink, on a /tmp shared with other users) fails the
-- render instead of being followed and written through.
local function write_output(path, data)
  pcall(uv.fs_unlink, path)
  -- A closure rather than pcall(uv.fs_open, ...): passing the function itself
  -- hides the argument count, so LuaLS cannot tell the sync overload (an fd)
  -- from the async one (a request handle).
  local ok_open, fd = pcall(function()
    return uv.fs_open(path, 'wx', 384) -- 0600
  end)
  if not ok_open or not fd then
    return false
  end
  local ok_write = pcall(function()
    local off = 0
    while off < #data do
      -- sub() on the first pass would re-intern the whole render.
      local written = uv.fs_write(fd, off == 0 and data or data:sub(off + 1), off)
      if not written or written <= 0 then
        error('short write')
      end
      off = off + written
    end
  end)
  pcall(uv.fs_close, fd)
  if not ok_write then
    pcall(uv.fs_unlink, path)
  end
  return ok_write
end

--- Render `infile` to `outfile`, returning the status line a client reads
--- ("ok" or "err:<reason>").
local function render_request(infile, outfile, cwd, cols, layout)
  last_request = uv.now()

  local stale = fingerprint() ~= generation

  local f = io.open(infile, 'rb')
  if not f then
    return 'err:input'
  end
  local input = f:read('*a') or ''
  f:close()

  local key = table.concat({ vim.fn.sha256(input), cwd, tostring(cols), tostring(layout) }, '\0')
  local rendered = not stale and cache_get(key) or nil
  if not rendered then
    local ok, result, cacheable = pcall(core.render, input, {
      cwd = cwd,
      cols = cols,
      layout = layout,
    })
    rendered = ok and result or input
    if ok and cacheable then
      cache_put(key, rendered)
    end
  end

  -- A client that lazygit killed mid-render has already run its cleanup, and
  -- nobody is left to remove an output written after that. The client unlinks
  -- its input before its output, so an input that is still there once the
  -- output is on disk means that cleanup is still to come and takes the
  -- output with it; one that is gone means the output is ours to remove.
  if not uv.fs_stat(infile) then
    return 'err:input'
  end
  if not write_output(outfile, rendered) then
    return 'err:output'
  end
  if not uv.fs_stat(infile) then
    pcall(uv.fs_unlink, outfile)
    return 'err:input'
  end

  if stale then
    -- Serve this request with the old world, then let the next spawn reload
    -- fresh parsers / nvim runtime.
    vim.defer_fn(shutdown, 50)
  end
  return 'ok'
end

-- -------------------------------------------------------------------- pipe ---
-- lazygit starts a fresh client process for every diff it draws, so whatever
-- that client costs to start is paid on every keypress that moves the
-- selection. An `nvim --remote-expr` client would be ~36ms of startup before it
-- said a word; `nc -U` round-trips a line here in ~4ms, which is what keeps the
-- transport cheaper than the render it asks for.
--
-- One request per connection, one line, tab separated, answered with one line:
--   render\t<in>\t<out>\t<cols>\t<layout>\t<cwd>  =>  ok | ok:owner | err:<why>
--   owner\t<pid>  (0: the client found none)      =>  ok
-- cwd comes last because it is the only field that can legitimately contain a
-- tab, so it simply takes the rest of the line.

local MAX_REQUEST_BYTES = 8 * 1024

local pipe_server = assert(uv.new_pipe(false))
local rendering = false
local queue = {}

local function reply(client, message)
  if client:is_closing() then
    return
  end
  client:write(message .. '\n', function()
    client:shutdown(function()
      if not client:is_closing() then
        client:close()
      end
    end)
  end)
end

local function dispatch(request)
  local pid = tonumber(request:match('^owner\t(%d+)$'))
  if pid then
    owner_answered = uv.now()
    if pid > 0 then
      watched[pid] = true
      saw_owner = true
    else
      owner_declined = owner_answered
    end
    return 'ok'
  end
  local infile, outfile, cols, layout, cwd =
    request:match('^render\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$')
  if not infile then
    return 'err:request'
  end
  -- The wire carries every field as a string; convert once here rather than at
  -- each use, so the cache key and the render see the same typed value.
  local status = render_request(infile, outfile, cwd, tonumber(cols), layout)
  if status == 'ok' and want_owner() then
    return 'ok:owner'
  end
  return status
end

-- One render at a time. `vim.wait` inside the git object session pumps the
-- event loop, so a second client's request arrives *during* a render: queueing
-- it keeps two renders from interleaving on one Lua stack (and two voices off
-- the one `git cat-file` pipe). The fresh request is enqueued like any other
-- rather than run ahead of the loop -- when `rendering` is false the queue is
-- empty, so it is served first either way.
local function submit(request, client)
  queue[#queue + 1] = { request = request, client = client }
  if rendering then
    return
  end
  rendering = true
  while queue[1] do
    local job = table.remove(queue, 1)
    local ok, status = pcall(dispatch, job.request)
    reply(job.client, ok and status or 'err:internal')
  end
  rendering = false
end

local function on_connection(err)
  if err then
    return
  end
  local client = assert(uv.new_pipe(false))
  local accepted = pcall(function()
    assert(pipe_server:accept(client))
  end)
  if not accepted then
    client:close()
    return
  end

  local chunks, bytes, done = {}, 0, false
  local function abort()
    done = true
    client:close()
  end
  client:read_start(function(read_err, chunk)
    if done then
      return
    end
    local request = nil
    if read_err then
      return abort()
    elseif chunk then
      chunks[#chunks + 1] = chunk
      bytes = bytes + #chunk
      if chunk:find('\n', 1, true) then
        local buf = table.concat(chunks)
        request = buf:sub(1, buf:find('\n', 1, true) - 1)
      elseif bytes > MAX_REQUEST_BYTES then
        return abort()
      end
    else
      -- nc half-closes its write side as soon as its own stdin ends, so EOF is
      -- the other end of a request that arrived without its newline.
      request = bytes > 0 and table.concat(chunks) or nil
      if not request then
        return abort()
      end
    end
    if request then
      done = true
      client:read_stop()
      -- Off the callback and onto the main loop: a render is nothing but calls
      -- (vim.fn, treesitter, vim.system) that a libuv callback is not allowed
      -- to make, and every one of them errors out of a fast event context.
      vim.schedule(function()
        submit(request, client)
      end)
    end
  end)
end

-- A bind that fails means another daemon holds the path (two clients can spawn
-- one at the same moment). That one is serving, and this process has no
-- transport of its own left to fall back on, so it exits rather than lingering
-- as a daemon that answers nothing.
local bound = pcall(function()
  assert(pipe_server:bind(PIPE_PATH))
  assert(pipe_server:listen(64, on_connection))
end)
if not bound then
  pcall(pipe_server.close, pipe_server)
  os.exit(0)
end
pipe_ino = (uv.fs_stat(PIPE_PATH) or {}).ino
