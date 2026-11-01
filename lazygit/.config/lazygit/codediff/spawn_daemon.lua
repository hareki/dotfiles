-- Usage: nvim --clean -l spawn_daemon.lua
--
-- Spawns daemon.lua fully detached (new session, no controlling terminal).
-- This matters because lazygit closes its render pty after every task, which
-- SIGHUPs the pty's process group; nvim exits on SIGHUP regardless of nohup,
-- so the daemon must not belong to that session at all.

local script = arg[0]
local dir = vim.fn.fnamemodify(script, ':p:h')

local handle = vim.uv.spawn(vim.v.progpath, {
  args = { '--clean', '-l', dir .. '/daemon.lua' },
  detached = true,
}, function() end)

os.exit(handle and 0 or 1)
