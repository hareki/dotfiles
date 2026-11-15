-- Persistent render daemon, started by spawn_daemon.lua as:
--   nvim --clean -l daemon.lua
-- Under -l any error exits, so a broken renderer leaves no daemon that answers nothing. It exits
-- once no lazygit runs, and recycles after a request once anything a render loads changes.

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
package.path = dir .. '/?.lua;' .. package.path

local bootstrap = require('lib.bootstrap')

local uv = vim.uv

-- The client owns the socket name; without its handoff there is nothing to serve.
local PIPE_PATH = assert(vim.env.CODEDIFF_PIPE)
-- Read once: fingerprint() runs in a libuv callback, where vim.v raises.
local PROGPATH = vim.v.progpath
local IDLE_MS = 60 * 60 * 1000
-- Idle time allowed with no lazygit running: keeps a hand-run client warm, reaps within seconds.
local IDLE_WITHOUT_LAZYGIT_MS = 10 * 1000
local POLL_MS = 3000
-- codediff's native engine leaks (myers.c frees only the winning path), ~14MB per rewrite-heavy
-- render, and no collection reaches it: past this the daemon recycles.
local MAX_RSS_BYTES = 512 * 1024 * 1024

-- Microseconds, not seconds: an edit in the snapshot's second would go unnoticed for good.
local function mtime_of(path)
  local st = uv.fs_stat(path)
  if not st then
    return 0
  end
  return st.mtime.sec * 1000000 + math.floor(st.mtime.nsec / 1000)
end

-- Newest mtime across the renderer's own sources, so an edit to them recycles the daemon.
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

-- Everything whose change must recycle the daemon, in one value, and all of bootstrap.paths: an
-- input listed once can't be snapshotted yet missed in the comparison.
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

-- os.exit skips nvim's socket cleanup, so unlink here, but only while the path is still ours:
-- a successor daemon may already have bound its own at the same name.
local function shutdown()
  local st = uv.fs_stat(PIPE_PATH)
  if st and st.ino == pipe_ino then
    os.remove(PIPE_PATH)
  end
  os.exit(0)
end

-- Any lazygit will do, since the daemon is shared. One pid's kill(0) per poll spares a pgrep spawn.
local lazygit = nil

-- Scheduled, as vim.system needs the main loop, which also keeps it from running inside a render.
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
local request = require('lib.request')

-- The pipe: one request per connection, one line in (lib/request.lua has its fields) and one back,
-- `ok` when the render reached the client's file, `err` when it did not.

local pipe_server = assert(uv.new_pipe(false))
local rendering = false

-- The client has its answer, so what submit held off runs with nobody waiting: a full collection
-- (which re-arms the collector), then the recycle checks on a size free of the render's garbage.
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

-- One render at a time: a scheduled callback holds the main loop, and catfile's wait takes fast
-- events only, so a second request stays scheduled until this one has answered.
local function submit(line, client)
  rendering = true
  last_request = uv.now()
  -- Collecting inside a render costs ~12% of the client's wait; right after it is idle (see reply).
  collectgarbage('stop')
  local ok, rendered = pcall(request.handle, line)
  reply(client, ok and rendered and 'ok' or 'err')
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
    local line = buf:match('^([^\n]*)\n')
    if line then
      client:read_stop()
      -- Onto the main loop: a render's vim.fn, treesitter and vim.system calls fail in fast events.
      vim.schedule(function()
        submit(line, client)
      end)
    elseif read_err or not chunk then
      client:close()
    end
  end)
end

-- A failed bind means another daemon holds the path (two clients spawned at once) and serves it,
-- so this one exits rather than linger answering nothing.
if not (pipe_server:bind(PIPE_PATH) and pipe_server:listen(64, on_connection)) then
  os.exit(0)
end
pipe_ino = uv.fs_stat(PIPE_PATH).ino

-- -l exits when this file ends, and every way out from here is an os.exit.
while true do
  vim.wait(IDLE_MS, nil, IDLE_MS)
end
