-- Persistent render daemon, started by client.sh as:
--   nvim --clean --headless --listen <sock> -c "luafile daemon.lua"
-- (-l would exit after running the script; -c keeps the server alive.)
-- Serves v:lua.CODEDIFF.render(...) requests from client.sh.
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
local IDLE_WITH_OWNER_MS = 60 * 60 * 1000
local IDLE_NO_OWNER_MS = 5 * 60 * 1000
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

-- Captured on the main loop: vim.v is not accessible from timer callbacks.
local socket_path = vim.v.servername
local socket_ino = (socket_path ~= "" and uv.fs_stat(socket_path) or {}).ino

local function shutdown(code)
  -- os.exit skips nvim's own socket cleanup, so unlink it here -- but only
  -- while it is still *our* socket: the path is shared by every daemon, and a
  -- successor may already have bound its own at the same name.
  if socket_path and socket_path ~= "" then
    local st = uv.fs_stat(socket_path)
    if st and st.ino == socket_ino then
      pcall(os.remove, socket_path)
    end
  end
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
  if saw_owner and next(watched) == nil then
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

_G.CODEDIFF = {}

function _G.CODEDIFF.render(infile, outfile, cwd, cols, owner_pid, layout)
  last_request = uv.now()
  local pid = tonumber(owner_pid)
  if pid then
    watched[pid] = true
    saw_owner = true
  end

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

  local out = io.open(outfile, "wb")
  if not out then
    return "err:output"
  end
  out:write(rendered)
  out:close()

  if stale then
    -- Serve this request with the old world, then let the next spawn reload
    -- fresh parsers / nvim runtime.
    vim.defer_fn(shutdown, 50)
  end
  return "ok"
end
