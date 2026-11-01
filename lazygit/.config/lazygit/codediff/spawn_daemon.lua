-- Usage: CODEDIFF_PIPE=<socket> nvim --clean -l spawn_daemon.lua
--
-- Spawns daemon.lua fully detached (new session, no controlling terminal).
-- This matters because lazygit closes its render pty after every task, which
-- SIGHUPs the pty's process group; nvim exits on SIGHUP regardless of nohup,
-- so the daemon must not belong to that session at all.
--
-- Exits 0 once the socket is there. The daemon binds it when it has bootstrapped
-- its parsers, so its arrival is also the signal that a render will be answered
-- rather than queued behind a second of startup. Past the wait, or with no
-- daemon to wait for, it exits 1: there is nothing for the client to ask.

local WAIT_MS = 2000

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
local pipe = vim.env.CODEDIFF_PIPE

local handle = vim.uv.spawn(vim.v.progpath, {
  args = { '--clean', '-l', dir .. '/daemon.lua' },
  detached = true,
}, function() end)

local bound = handle and vim.wait(WAIT_MS, function()
  return vim.uv.fs_stat(pipe) ~= nil
end, 5)

os.exit(bound and 0 or 1)
