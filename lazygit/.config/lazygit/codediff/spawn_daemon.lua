-- Usage: CODEDIFF_PIPE=<socket> nvim --clean -l spawn_daemon.lua
--
-- Spawns daemon.lua fully detached (new session, no controlling terminal).
-- This matters because lazygit closes its render pty after every task, which
-- SIGHUPs the pty's process group; nvim exits on SIGHUP regardless of nohup,
-- so the daemon must not belong to that session at all.
--
-- Exits 0 once the socket is there. The daemon binds it when it has bootstrapped
-- its parsers, so its arrival is also the signal that a render will be answered
-- rather than queued behind a second of startup. The wait ends early when the
-- daemon exits: one that failed to start will never bind, and one that lost the
-- socket to another daemon leaves that one's to ask. With no socket by then, it
-- exits 1: there is nothing for the client to ask.

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
