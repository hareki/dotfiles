-- Persistent render daemon, started by client.sh as:
--   nvim --clean --headless --listen <sock> -c "luafile daemon.lua"
-- (-l would exit after running the script; -c keeps the server alive.)
--
-- Two transports serve the same render:
--   * a plain line protocol on <sock-without-.sock>.pipe, which is what every
--     render actually uses -- see the pipe section at the bottom;
--   * v:lua.CODEDIFF.render(...) over nvim's own RPC socket, the fallback for a
--     machine whose client.sh cannot reach the first one.
--
-- Lifetime: exits when every lazygit process that ever used it is gone (polled
-- every few seconds), so quitting lazygit (or the nvim :terminal hosting it)
-- leaves no orphaned daemon. Idle timeouts back that up, and a change to the
-- nvim binary, installed parsers or codediff.nvim recycles the daemon on the
-- next request.

local script = arg and arg[0] or debug.getinfo(1, "S").source:sub(2)
local dir = vim.fn.fnamemodify(script, ":p:h")
package.path = dir .. "/?.lua;" .. package.path

local uv = vim.uv

-- The spawning render task's pty goes away right after we start; SIGHUP from
-- that teardown must not kill the daemon.
uv.new_signal():start("sighup", function() end)

local PARSER_DIR = vim.fs.normalize("~/.local/share/nvim/site/parser")
-- VERSION changes whenever the plugin (and its native diff library) updates.
local CODEDIFF_VERSION = vim.fs.normalize("~/.local/share/nvim/lazy/codediff.nvim/VERSION")
-- The editor's filetype-rules module that bootstrap sources into the daemon:
-- its detection rules and ft => language aliases shape every render, so an
-- edit must recycle the daemon like any renderer source.
local FILETYPE_RULES = vim.fs.joinpath(vim.fn.stdpath("config"), "lua/config/filetypes/init.lua")
-- Derived the same way client.sh derives it, rather than from v:servername, so
-- an nvim that failed to bind its own RPC socket still serves the fast path.
local TMP = ((vim.env.TMPDIR or "/tmp"):gsub("/+$", ""))
local PIPE_PATH = string.format("%s/lazygit-codediff-%s.pipe", TMP, vim.env.USER or "u")
local IDLE_WITH_OWNER_MS = 60 * 60 * 1000
local IDLE_NO_OWNER_MS = 5 * 60 * 1000
-- Owners are registered on demand (a client walks its process tree only when
-- asked to), so an empty watch list also describes a live lazygit that has not
-- been asked yet. A short grace after the last request tells the two apart:
-- quitting lazygit still reaps the daemon within seconds, while a session whose
-- owner has not been registered yet keeps it alive by rendering at all.
local ORPHANED_GRACE_MS = 10 * 1000
-- An answer that asks for the owner costs the client a process tree walk, so a
-- client that answered that it found none (a manual pipe into the renderer, a
-- lazygit reached through some wrapper) is not asked again for this long.
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
  for _, d in ipairs({ dir, dir .. "/lib" }) do
    for name, kind in vim.fs.dir(d) do
      if kind == "file" then
        latest = math.max(latest, mtime_of(d .. "/" .. name))
      end
    end
  end
  return latest
end

-- Everything whose change must recycle the daemon, in one value: listing the
-- inputs once means a new one cannot be added to the snapshot but missed in the
-- comparison, which would silently never trigger a reload.
local function fingerprint()
  return table.concat({
    mtime_of(vim.v.progpath),
    mtime_of(PARSER_DIR),
    mtime_of(CODEDIFF_VERSION),
    mtime_of(FILETYPE_RULES),
    scripts_mtime(),
  }, ":")
end

local generation = fingerprint()

local watched = {}
local saw_owner = false
local last_request = uv.now()
local owner_declined = -OWNER_ASK_INTERVAL_MS

-- Captured on the main loop: vim.v is not accessible from timer callbacks.
local socket_path = vim.v.servername
local socket_ino = (socket_path ~= "" and uv.fs_stat(socket_path) or {}).ino
local pipe_ino = nil

-- os.exit skips nvim's own socket cleanup, so unlink here -- but only while the
-- path is still *ours*: both are shared by every daemon, and a successor may
-- already have bound its own at the same name.
local function unlink_own(path, ino)
  if path and path ~= "" and ino then
    local st = uv.fs_stat(path)
    if st and st.ino == ino then
      pcall(os.remove, path)
    end
  end
end

local function shutdown(code)
  unlink_own(socket_path, socket_ino)
  unlink_own(PIPE_PATH, pipe_ino)
  os.exit(code or 0)
end

local poll = uv.new_timer()
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
-- updated underneath us) would otherwise abort the -c luafile with the RPC
-- socket still bound, leaving a daemon that answers nothing and never exits
-- while every subsequent render spawns another one.
local ok_boot, core = pcall(function()
  require("lib.bootstrap").setup()
  return require("lib.core")
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
local CACHE_MAX = 8
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
    local oldest_key, oldest = nil, math.huge
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

local function watch_owner(pid)
  if pid and pid > 0 then
    watched[pid] = true
    saw_owner = true
  end
end

-- Whether this answer should ask the client for an owner pid. The throttle
-- starts from a client's *answer*, not from the ask: a client that lazygit
-- terminated between its render and its answer must not leave the daemon
-- unowned for the whole interval, so the next render simply asks again.
local function want_owner()
  return next(watched) == nil and uv.now() - owner_declined >= OWNER_ASK_INTERVAL_MS
end

-- The output path is derived from the client's mktemp'd input path rather than
-- made by a second mktemp of its own, so this is the one file the daemon
-- creates: O_EXCL after an unlink, never O_TRUNC, means a name somebody else
-- planted in between (a symlink, on a /tmp shared with other users) fails the
-- render instead of being followed and written through.
local function write_output(path, data)
  pcall(uv.fs_unlink, path)
  local ok_open, fd = pcall(uv.fs_open, path, "wx", 384) -- 0600
  if not ok_open or not fd then
    return false
  end
  local ok_write = pcall(function()
    local off = 0
    while off < #data do
      local written = uv.fs_write(fd, data:sub(off + 1), off)
      if not written or written <= 0 then
        error("short write")
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

  local f = io.open(infile, "rb")
  if not f then
    return "err:input"
  end
  local input = f:read("*a") or ""
  f:close()

  local key = table.concat({ vim.fn.sha256(input), cwd, tostring(cols), tostring(layout) }, "\0")
  local rendered = not stale and cache_get(key) or nil
  if not rendered then
    local ok, result, cacheable = pcall(core.render, input, {
      cwd = cwd,
      cols = tonumber(cols) or 120,
      layout = layout,
    })
    rendered = ok and result or input
    if ok and cacheable then
      cache_put(key, rendered)
    end
  end

  if not write_output(outfile, rendered) then
    return "err:output"
  end

  if stale then
    -- Serve this request with the old world, then let the next spawn reload
    -- fresh parsers / nvim runtime.
    vim.defer_fn(shutdown, 50)
  end
  return "ok"
end

_G.CODEDIFF = {}

--- RPC entry point, kept for clients that cannot reach the pipe below. Unlike
--- the pipe protocol it is handed the owner pid on every render: an
--- `nvim --remote-expr` client has already paid far more than a process tree
--- walk costs by the time it connects.
function _G.CODEDIFF.render(infile, outfile, cwd, cols, owner_pid, layout)
  watch_owner(tonumber(owner_pid))
  return render_request(infile, outfile, cwd, cols, layout)
end

-- -------------------------------------------------------------------- pipe ---
-- lazygit starts a fresh client process for every diff it draws, so whatever
-- that client costs to start is paid on every keypress that moves the
-- selection. An `nvim --remote-expr` client is ~36ms of startup before it says
-- a word; `nc -U` round-trips a line here in ~4ms, which is what keeps the
-- transport cheaper than the render it asks for.
--
-- One request per connection, one line, tab separated, answered with one line:
--   render\t<in>\t<out>\t<cols>\t<layout>\t<cwd>  =>  ok | ok:owner | err:<why>
--   owner\t<pid>  (0: the client found none)      =>  ok
--   ping                                          =>  pong
-- cwd comes last because it is the only field that can legitimately contain a
-- tab, so it simply takes the rest of the line.

local MAX_REQUEST_BYTES = 8 * 1024

local pipe_server = nil
local rendering = false
local queue = {}

local function reply(client, message)
  if client:is_closing() then
    return
  end
  client:write(message .. "\n", function()
    client:shutdown(function()
      if not client:is_closing() then
        client:close()
      end
    end)
  end)
end

local function dispatch(request)
  if request == "ping" then
    return "pong"
  end
  local pid = tonumber(request:match("^owner\t(%d+)$"))
  if pid then
    if pid > 0 then
      watch_owner(pid)
    else
      owner_declined = uv.now()
    end
    return "ok"
  end
  local infile, outfile, cols, layout, cwd = request:match("^render\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
  if not infile then
    return "err:request"
  end
  local status = render_request(infile, outfile, cwd, cols, layout)
  if status == "ok" and want_owner() then
    return "ok:owner"
  end
  return status
end

local function run(request, client)
  local ok, status = pcall(dispatch, request)
  reply(client, ok and status or "err:internal")
end

-- One render at a time. `vim.wait` inside the git object session pumps the
-- event loop, so a second client's request arrives *during* a render: queueing
-- it keeps two renders from interleaving on one Lua stack (and two voices off
-- the one `git cat-file` pipe).
local function submit(request, client)
  if rendering then
    queue[#queue + 1] = { request = request, client = client }
    return
  end
  rendering = true
  run(request, client)
  while queue[1] do
    local job = table.remove(queue, 1)
    run(job.request, job.client)
  end
  rendering = false
end

local function on_connection(err)
  if err or not pipe_server then
    return
  end
  local client = uv.new_pipe(false)
  local accepted = pcall(function()
    assert(pipe_server:accept(client))
  end)
  if not accepted then
    client:close()
    return
  end

  local chunks, bytes, done = {}, 0, false
  client:read_start(function(read_err, chunk)
    if done then
      return
    end
    local request = nil
    if read_err then
      done = true
      client:close()
      return
    elseif chunk then
      chunks[#chunks + 1] = chunk
      bytes = bytes + #chunk
      if chunk:find("\n", 1, true) then
        local buf = table.concat(chunks)
        request = buf:sub(1, buf:find("\n", 1, true) - 1)
      elseif bytes > MAX_REQUEST_BYTES then
        done = true
        client:close()
        return
      end
    else
      -- nc half-closes its write side as soon as its own stdin ends, so EOF is
      -- the other end of a request that arrived without its newline.
      request = bytes > 0 and table.concat(chunks) or nil
      if not request then
        done = true
        client:close()
        return
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
-- one at the same moment). It is serving; this process keeps the RPC entry
-- point alive for its own client and then idles out.
local server = uv.new_pipe(false)
local bound = pcall(function()
  assert(server:bind(PIPE_PATH))
  assert(server:listen(64, on_connection))
end)
if bound then
  pipe_server = server
  pipe_ino = (uv.fs_stat(PIPE_PATH) or {}).ino
else
  pcall(server.close, server)
end
