-- Usage: nvim --clean -l spawn_daemon.lua <socket>
--
-- Spawns daemon.lua fully detached (new session, no controlling terminal).
-- This matters because lazygit closes its render pty after every task, which
-- SIGHUPs the pty's process group; nvim exits on SIGHUP regardless of nohup,
-- so the daemon must not belong to that session at all.

local sock = arg[1]
local script = arg[0]
local dir = vim.fn.fnamemodify(script, ":p:h")

local handle = vim.uv.spawn(vim.v.progpath, {
  -- fnameescape: the path lands in an Ex command line, where an unescaped
  -- %, #, | or " would be expanded or would truncate the command.
  args = { "--clean", "--headless", "--listen", sock, "-c", "luafile " .. vim.fn.fnameescape(dir .. "/daemon.lua") },
  detached = true,
  stdio = { nil, nil, nil },
})

if handle then
  handle:unref()
end
os.exit(handle and 0 or 1)
