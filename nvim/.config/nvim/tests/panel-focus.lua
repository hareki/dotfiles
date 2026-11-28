-- Focus from the Snacks terminals: a full-screen panel hands window moves to tmux, the floating
-- terminal hides once a normal window or its panel has focus, and hide_others keeps one panel up

local t = require('tests.lib.helpers')
local terminals = require('core.snacks-nvim.terminals')
local lazy = require('lazy')

-- The move keys are lazy.nvim's stubs until the plugin loads
lazy.load({ plugins = { 'vim-tmux-navigator' } })

--- Close the terminals the running test opened when it ends
local function close_terminals_after()
  t.cleanup(function()
    for _, terminal in ipairs(Snacks.terminal.list()) do
      terminal:close()
    end
  end)
end

--- @param count? integer Snacks keys its terminals on the command and count: one panel per count
--- @return snacks.win
local function open_panel(count)
  close_terminals_after()
  return Snacks.terminal.open(
    { 'sleep', '1000' },
    { count = count, win = terminals.win_config({ position = 'float' }) }
  )
end

--- Press `<A-t>`, with a shell that starts at once
--- @return snacks.win
local function open_floating_terminal()
  close_terminals_after()
  t.set(vim.o, 'shell', '/bin/sh')
  t.map_callback('n', '<A-t>')()

  local win = vim.api.nvim_get_current_win()
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal.win == win then
      return terminal
    end
  end
  error('no terminal opened')
end

--- Split the editor in two, focus on the right window
--- @return integer left
--- @return integer right
local function split()
  local left = vim.api.nvim_get_current_win()
  vim.cmd.vsplit()
  local right = vim.api.nvim_get_current_win()
  t.cleanup(function()
    vim.api.nvim_win_close(right, true)
  end)
  return left, right
end

--- Record the tmux commands sent until the test ends, running none
--- @return string[][] commands
local function spy_tmux()
  local system = vim.system
  local commands = {}
  t.set(vim, 'system', function(cmd, ...)
    if cmd[1] ~= 'tmux' then
      return system(cmd, ...)
    end
    commands[#commands + 1] = cmd
  end)
  return commands
end

t.test('a move key goes to the window on that side', function()
  local left, right = split()

  t.map_callback('n', '<A-m>')()
  t.eq(vim.api.nvim_get_current_win(), left, '<A-m>')
  t.map_callback('n', '<A-i>')()
  t.eq(vim.api.nvim_get_current_win(), right, '<A-i>')
end)

t.test('outside tmux, a move key keeps a full-screen panel focused', function()
  split()
  local panel = open_panel()
  local commands = spy_tmux()

  t.map_callback('t', '<A-m>')()
  t.eq(vim.api.nvim_get_current_win(), panel.win, 'the focused window')
  t.eq(commands, {}, 'tmux commands')
end)

t.test('inside tmux, a move key takes a full-screen panel straight to the next pane', function()
  split()
  local panel = open_panel()
  local commands = spy_tmux()
  t.set(vim.env, 'TMUX', '/tmp/tmux-test,1,0')
  t.set(vim.env, 'TMUX_PANE', '%7')

  t.map_callback('t', '<A-m>')()
  t.map_callback('t', '<A-n>')()
  t.map_callback('t', '<A-e>')()
  t.map_callback('t', '<A-i>')()

  t.eq(vim.api.nvim_get_current_win(), panel.win, 'the focused window')
  t.eq(commands, {
    { 'tmux', 'select-pane', '-t', '%7', '-L', '-Z' },
    { 'tmux', 'select-pane', '-t', '%7', '-D', '-Z' },
    { 'tmux', 'select-pane', '-t', '%7', '-U', '-Z' },
    { 'tmux', 'select-pane', '-t', '%7', '-R', '-Z' },
  }, 'tmux commands')
end)

t.test('the floating terminal hides once a move key lands in a normal window', function()
  local win = vim.api.nvim_get_current_win()
  local terminal = open_floating_terminal()
  t.eq(vim.api.nvim_get_current_win(), terminal.win, 'the terminal has focus')

  t.map_callback('t', '<A-m>')()
  t.eq(vim.api.nvim_get_current_win(), win, 'the focused window')
  t.wait_for(function()
    return not terminal:valid()
  end, 'the terminal to hide')
  t.ok(terminal:buf_valid(), 'its buffer lives on')

  t.map_callback('n', '<A-t>')()
  t.ok(terminal:valid(), '<A-t> shows it again')
  vim.api.nvim_set_current_win(win)
  t.wait_for(function()
    return not terminal:valid()
  end, 'the reshown terminal to hide')
end)

t.test('the floating terminal stays under another float', function()
  local terminal = open_floating_terminal()

  local float = t.float(true)
  t.settle()
  t.ok(terminal:valid(), 'the terminal still shows')

  vim.api.nvim_win_close(float, true)
  t.settle()
  t.eq(vim.api.nvim_get_current_win(), terminal.win, 'focus is back in the terminal')
end)

t.test('over a full-screen panel, a move key lands on the panel and hides the terminal', function()
  split()
  local panel = open_panel()
  local terminal = open_floating_terminal()
  local commands = spy_tmux()
  t.set(vim.env, 'TMUX', '/tmp/tmux-test,1,0')
  t.set(vim.env, 'TMUX_PANE', '%7')

  t.map_callback('t', '<A-i>')()
  t.eq(vim.api.nvim_get_current_win(), panel.win, 'the focused window')
  t.eq(commands, {}, 'tmux commands')
  t.wait_for(function()
    return not terminal:valid()
  end, 'the terminal to hide')

  t.map_callback('t', '<A-i>')()
  t.eq(commands, { { 'tmux', 'select-pane', '-t', '%7', '-R', '-Z' } }, 'the next move')
end)

t.test('the floating terminal stays under a full-screen panel opened over it', function()
  local terminal = open_floating_terminal()
  local panel = open_panel()
  t.settle()
  t.ok(terminal:valid(), 'the terminal still shows')

  panel:close()
  t.settle()
  t.eq(vim.api.nvim_get_current_win(), terminal.win, 'focus is back in the terminal')
end)

t.test('a full-screen panel stays when a normal window takes focus', function()
  local win = vim.api.nvim_get_current_win()
  local panel = open_panel()

  vim.api.nvim_set_current_win(win)
  t.settle()
  t.ok(panel:valid(), 'the panel still shows')
end)

t.test('hide_others hides every full-screen panel but the one about to toggle', function()
  local first = open_panel(1)
  local second = open_panel(2)
  t.ok(first:valid(), 'the first panel hid under the second')

  terminals.hide_others(second.buf)
  t.ok(not first:valid(), 'the other panel still shows')
  t.ok(first:buf_valid(), 'its buffer lives on')
  t.eq(terminals.visible(), second, 'the panel up')

  -- The documented no-op: with its own panel up, no other can be
  terminals.hide_others(second.buf)
  t.eq(terminals.visible(), second, 'the panel up after a second call')

  terminals.hide_others(nil)
  t.eq(terminals.visible(), nil, 'the panel up once none is about to toggle')
end)

t.test('hide_others leaves the floating terminal', function()
  local terminal = open_floating_terminal()

  terminals.hide_others(nil)
  t.ok(terminal:valid(), 'the terminal hid')
end)
