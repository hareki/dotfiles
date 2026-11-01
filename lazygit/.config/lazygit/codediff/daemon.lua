-- Persistent render daemon, started by spawn_daemon.lua as:
--   nvim --clean -l daemon.lua
-- Under -l an error anywhere in this file exits the process, so a broken renderer
-- leaves no daemon that answers nothing while every render spawns another; the
-- server lives in the wait at the bottom.
--
-- Renders arrive over a plain line protocol on a unix socket -- see the pipe
-- section at the bottom.
--
-- Lifetime: exits once no lazygit is running (polled every few seconds), so
-- quitting lazygit (or the nvim :terminal hosting it) leaves no orphaned daemon.
-- An idle timeout backs that up, and a change to the nvim binary, to the
-- renderer's own sources or to anything bootstrap loads (parsers, plugins,
-- filetype rules) recycles the daemon after the next request.

local script = debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(script, ':p:h')
package.path = dir .. '/?.lua;' .. package.path

local bootstrap = require('lib.bootstrap')

local uv = vim.uv

-- The client owns the socket name and hands it down through the spawner's
-- environment. Deriving it a second time here would be the same cross-process
-- invariant spelled in two languages, kept in step by hand; without the handoff
-- there is nothing to serve.
local PIPE_PATH = assert(vim.env.CODEDIFF_PIPE)
-- Read once: fingerprint() runs in a libuv callback, where vim.v raises.
local PROGPATH = vim.v.progpath
local IDLE_MS = 60 * 60 * 1000
-- How long it may sit idle with no lazygit running. Long enough for a client run
-- by hand to keep it warm, while quitting lazygit still reaps it within seconds.
local IDLE_WITHOUT_LAZYGIT_MS = 10 * 1000
local POLL_MS = 3000
-- codediff's native diff engine leaks (libvscode-diff/src/myers.c frees only the
-- winning path of its search): ~14MB per render of a rewrite-heavy commit, and
-- next to nothing for a small one. No collection here can reach that, so a
-- lazygit left open would grow the daemon without bound; past this it recycles.
local MAX_RSS_BYTES = 512 * 1024 * 1024

-- Microseconds, not seconds: a whole-second resolution lets an edit that lands
-- in the same second as the snapshot go unnoticed for the daemon's lifetime.
local function mtime_of(path)
  local st = uv.fs_stat(path)
  if not st then
    return 0
  end
  return st.mtime.sec * 1000000 + math.floor(st.mtime.nsec / 1000)
end

-- Newest mtime across the renderer's own sources, so editing them recycles
-- the daemon instead of it serving stale code.
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
-- comparison, which would silently never trigger a reload. Bootstrap owns the
-- list of paths a render depends on, so this reads that list rather than
-- re-deriving it, and reads *all* of it: a dependency added there cannot be one
-- the fingerprint forgot.
local function fingerprint()
  local parts = { mtime_of(PROGPATH), scripts_mtime() }
  for _, path in pairs(bootstrap.paths) do
    parts[#parts + 1] = mtime_of(path)
  end
  return table.concat(parts, ':')
end

local generation = fingerprint()

local last_request = uv.now()

local pipe_ino = nil

-- os.exit skips nvim's own socket cleanup, so unlink here -- but only while the
-- path is still *ours*: it is shared by every daemon, and a successor may
-- already have bound its own at the same name.
local function shutdown()
  local st = uv.fs_stat(PIPE_PATH)
  if st and st.ino == pipe_ino then
    os.remove(PIPE_PATH)
  end
  os.exit(0)
end

-- Any lazygit will do: the daemon is shared, and a request says nothing about
-- which one sent it. Watching one pid costs a syscall per poll where pgrep costs
-- a spawn, so pgrep only speaks up once that pid is gone.
local lazygit = nil

-- Scheduled, because vim.system needs the main loop; a render holds that, so this
-- never runs inside one.
local poll = assert(uv.new_timer())
poll:start(
  POLL_MS,
  POLL_MS,
  vim.schedule_wrap(function()
    local idle = uv.now() - last_request
    if idle > IDLE_MS then
      shutdown()
    elseif idle > IDLE_WITHOUT_LAZYGIT_MS and not (lazygit and uv.kill(lazygit, 0)) then
      vim.system({ 'pgrep', 'lazygit' }, { text = true }, function(result)
        lazygit = tonumber(result.stdout:match('%d+'))
        if not lazygit then
          shutdown()
        end
      end)
    end
  end)
)

bootstrap.setup()
local core = require('lib.core')

-- Rendered-output cache: browsing commits in lazygit re-requests the same diff
-- every time the selection returns to it, and the expensive renders (large
-- commits) are exactly the ones worth never paying twice. Keyed by the full
-- input plus everything else that shapes the output, which holds for an unstaged
-- diff too: its index line names the worktree content it shows. A daemon recycle
-- (parser/plugin/source updates) drops the cache with the process.
-- Sized so the byte ceiling below stays the binding constraint rather than this
-- count: a single file's diff renders to well under a megabyte, so 32 MB is
-- room for dozens, and a commit-sized render still leaves room for twenty.
-- A lookup is an O(n) scan, trivial at this size.
local CACHE_MAX = 24
-- Rendered ANSI runs ~5-8x its input (tinted rows pad out to the full width),
-- so a handful of large-commit renders can pin tens of MB for the daemon's
-- lifetime; the byte ceiling bounds memory where the entry count cannot.
local CACHE_MAX_BYTES = 32 * 1024 * 1024
local cache, cache_bytes = {}, 0 -- least recently used first

local function cache_get(key)
  for i, e in ipairs(cache) do
    if e.key == key then
      table.insert(cache, table.remove(cache, i))
      return e.out
    end
  end
end

local function cache_put(key, out)
  if #out > CACHE_MAX_BYTES then
    return
  end
  cache[#cache + 1] = { key = key, out = out }
  cache_bytes = cache_bytes + #out
  while #cache > CACHE_MAX or cache_bytes > CACHE_MAX_BYTES do
    cache_bytes = cache_bytes - #table.remove(cache, 1).out
  end
end

-- Opens the file the client made rather than creating one, in the private
-- directory the client made for it. A client that lazygit killed mid-render has
-- already removed that directory, and nobody is left to remove an output
-- written after that, so a render that outlives its client has to fail here.
local function write_output(path, data)
  local f = io.open(path, 'r+b')
  if not f then
    return false
  end
  local written = f:write(data)
  return f:close() and written ~= nil
end

-- The cache key for rendering `input` with `opts`. Every option core.render is
-- handed takes part, so an option added later cannot be left out of the key and
-- have a render made for other options served in its place.
local function cache_key(input, opts)
  local parts = { vim.fn.sha256(input) }
  for name, value in vim.spairs(opts) do
    parts[#parts + 1] = name .. '=' .. tostring(value)
  end
  return table.concat(parts, '\0')
end

--- Render `infile` to `outfile` with core.render `opts`, returning the status
--- line a client reads ("ok" or "err:<reason>").
local function render_request(infile, outfile, opts)
  last_request = uv.now()

  local f = io.open(infile, 'rb')
  if not f then
    return 'err:input'
  end
  local input = f:read('*a')
  f:close()

  local key = cache_key(input, opts)
  local rendered = cache_get(key)
  if not rendered then
    local ok, result, cacheable = pcall(core.render, input, opts)
    rendered = ok and result or input
    if ok and cacheable then
      cache_put(key, rendered)
    end
  end

  return write_output(outfile, rendered) and 'ok' or 'err:output'
end

-- -------------------------------------------------------------------- pipe ---
-- One request per connection, one line, tab separated, answered with one line:
--   render\t<in>\t<out>\t<cols>\t<layout>\t<metadata>\t<cwd>
--                                    =>  ok | err:<why>
-- <metadata> is 1 when the render is to carry OSC 1717 records, 0 otherwise.
-- cwd comes last because it is the only field that can legitimately contain a
-- tab, so it simply takes the rest of the line.

local pipe_server = assert(uv.new_pipe(false))
local rendering = false

-- The client is on its way by the time this runs, so whatever submit held off
-- runs after it, with nobody waiting: a full cycle, which also re-arms the
-- collector, and then the checks that recycle the daemon. What the cycle leaves
-- resident is the daemon's real size, without a render's garbage in it. A staler
-- world served this one request, and the next spawn loads the fresh one.
local function reply(client, message)
  client:write(message .. '\n', function()
    client:close()
    if not rendering then
      collectgarbage('collect')
      if uv.resident_set_memory() > MAX_RSS_BYTES or fingerprint() ~= generation then
        shutdown()
      end
    end
  end)
end

local function dispatch(request)
  local infile, outfile, cols, layout, metadata, cwd =
    request:match('^render\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([01])\t(.*)$')
  if not infile then
    return 'err:request'
  end
  -- The wire carries every field as a string; convert once here rather than at
  -- each use, so the cache key and the render see the same typed value.
  return render_request(infile, outfile, {
    cwd = cwd,
    cols = tonumber(cols),
    layout = layout,
    metadata = metadata == '1',
  })
end

-- One render at a time: a scheduled callback holds the main loop, and the wait
-- on the git object session (lib/catfile.lua) takes fast events only, so a
-- second client's request stays scheduled until this one has answered.
local function submit(request, client)
  rendering = true
  -- Collecting inside a render is ~12% of the wall clock a client sees, and the
  -- moment right after it is idle (see reply).
  collectgarbage('stop')
  local ok, status = pcall(dispatch, request)
  reply(client, ok and status or 'err:internal')
  rendering = false
end

local function on_connection(err)
  if err then
    return
  end
  local client = assert(uv.new_pipe(false))
  if not pipe_server:accept(client) then
    client:close()
    return
  end

  local buf = ''
  client:read_start(function(read_err, chunk)
    buf = buf .. (chunk or '')
    local request = buf:match('^([^\n]*)\n')
    if request then
      client:read_stop()
      -- Off the callback and onto the main loop: a render is nothing but calls
      -- (vim.fn, treesitter, vim.system) that a libuv callback is not allowed
      -- to make, and every one of them errors out of a fast event context.
      vim.schedule(function()
        submit(request, client)
      end)
    elseif read_err or not chunk then
      client:close()
    end
  end)
end

-- A bind that fails means another daemon holds the path (two clients can spawn
-- one at the same moment). That one is serving, and this process has no
-- transport of its own left to fall back on, so it exits rather than lingering
-- as a daemon that answers nothing.
if not (pipe_server:bind(PIPE_PATH) and pipe_server:listen(64, on_connection)) then
  os.exit(0)
end
pipe_ino = uv.fs_stat(PIPE_PATH).ino

-- -l exits when this file ends, and every way out from here is an os.exit.
while true do
  vim.wait(IDLE_MS, nil, IDLE_MS)
end
