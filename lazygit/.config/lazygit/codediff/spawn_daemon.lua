-- Usage: CODEDIFF_PIPE=<socket> nvim --clean -l spawn_daemon.lua
--
-- Spawns daemon.lua detached in a new session: closing lazygit's render pty SIGHUPs its process
-- group, and nvim exits on SIGHUP regardless of nohup.
--
-- Exits 0 once the socket is there, bound after bootstrap so a render won't queue behind startup;
-- 1 when none is there by the time the daemon exits or the wait runs out.

local WAIT_MS = 2000

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
local pipe = vim.env.CODEDIFF_PIPE

local function listening()
  return vim.uv.fs_stat(pipe) ~= nil
end

local exited = false
local handle = vim.uv.spawn(vim.v.progpath, {
  args = { '--clean', '-l', dir .. '/daemon.lua' },
  detached = true,
}, function()
  exited = true
end)

if handle then
  vim.wait(WAIT_MS, function()
    return exited or listening()
  end, 5)
end

os.exit(listening() and 0 or 1)
