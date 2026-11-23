-- features.git.snacks-nvim.lazygit's toggle, through <A-g>, with a stand-in for lazygit on the
-- PATH that writes down its arguments and waits: the single instance it keeps, the file it preselects
-- and the full-screen panel it hides first. lazygit itself is out of reach; its edit command is
-- tests/entry-points.lua's

local t = require('tests.lib.helpers')
local terminals = require('core.snacks-nvim.terminals')

local BIN = vim.fs.joinpath(vim.uv.cwd(), 'bin')
-- Where the stand-in writes its arguments, one per line: the terminal would wrap a long path
local ARGS = vim.fs.joinpath(vim.uv.cwd(), 'lazygit-args')
vim.fn.mkdir(BIN, 'p')
vim.fn.writefile({
  '#!/bin/sh',
  string.format('printf "%%s\\n" "$@" > %s', vim.fn.shellescape(ARGS .. '.tmp')),
  string.format('mv %s %s', vim.fn.shellescape(ARGS .. '.tmp'), vim.fn.shellescape(ARGS)),
  'exec sleep 1000',
}, vim.fs.joinpath(BIN, 'lazygit'))
vim.fn.setfperm(vim.fs.joinpath(BIN, 'lazygit'), 'rwxr-xr-x')

--- Put the stand-in first on the PATH, and close the terminals the test opened when it ends
local function stand_in()
  t.set(vim.env, 'PATH', BIN .. ':' .. vim.env.PATH)
  t.cleanup(function()
    for _, terminal in ipairs(Snacks.terminal.list()) do
      terminal:close()
    end
    vim.fn.delete(ARGS)
  end)
end

--- @return snacks.win?
local function lazygit_terminal()
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if vim.b[terminal.buf].snacks_terminal.cmd[1] == 'lazygit' then
      return terminal
    end
  end
end

--- Press <A-g>, in Terminal mode as a panel would be, or Normal mode from the code
local function press()
  t.map_callback(vim.bo.buftype == 'terminal' and 't' or 'n', '<A-g>')()
end

--- The arguments the stand-in started with, once it has
--- @return string[]
local function started_with()
  t.wait_for(function()
    return vim.uv.fs_stat(ARGS) ~= nil
  end, 'the stand-in to start')
  return vim.fn.readfile(ARGS)
end

t.test('<A-g> starts lazygit on the current file, in a full-screen panel', function()
  stand_in()
  local path = vim.api.nvim_buf_get_name(t.file('current.txt', { 'text' }))

  press()
  local terminal = t.ok(lazygit_terminal(), 'no lazygit terminal')
  t.eq(started_with(), { '--file', path }, 'the arguments')
  t.eq(terminals.visible(), terminal, 'the full-screen panel up')
  t.eq(vim.api.nvim_get_current_win(), terminal.win, 'the window in focus')
  t.eq(vim.api.nvim_win_get_config(terminal.win).title[1][1], ' Git Client ', 'the title')
end)

t.test('<A-g> again hides it, and once more shows that same lazygit', function()
  stand_in()
  local code_win = vim.api.nvim_get_current_win()
  t.file('again.txt', { 'text' })

  press()
  local terminal = t.ok(lazygit_terminal(), 'no lazygit terminal')
  local buf = t.ok(terminal.buf, 'no terminal buffer')
  started_with()

  press()
  t.ok(not terminal:valid(), 'the panel shows after the second press')
  t.eq(vim.api.nvim_buf_is_valid(buf), true, 'the terminal buffer after the second press')
  t.eq(vim.api.nvim_get_current_win(), code_win, 'the window in focus')

  -- From another file too: Snacks keys an instance on its command, --file included
  t.file('other.txt', { 'text' })
  press()
  t.eq(lazygit_terminal(), terminal, 'the terminal after the third press')
  t.ok(terminal:valid(), 'the panel hidden after the third press')
  t.eq(terminal.buf, buf, 'the buffer after the third press')
  t.eq(#Snacks.terminal.list(), 1, 'the terminals')
end)

t.test('<A-g> from a buffer with no file preselects the file focused last', function()
  stand_in()
  local path = vim.api.nvim_buf_get_name(t.file('last.txt', { 'text' }))
  t.buffer()

  press()
  t.eq(started_with(), { '--file', path })
end)

t.test('<A-g> hides the full-screen panel up before it shows', function()
  stand_in()
  t.file('panels.txt', { 'text' })
  local other = Snacks.terminal.open(
    { 'sleep', '1000' },
    { win = terminals.win_config({ position = 'float' }) }
  )
  t.eq(terminals.visible(), other, 'the panel up before the press')

  press()
  local terminal = t.ok(lazygit_terminal(), 'no lazygit terminal')
  t.ok(not other:valid(), 'the other panel shows')
  t.eq(terminals.visible(), terminal, 'the panel up after the press')
end)
