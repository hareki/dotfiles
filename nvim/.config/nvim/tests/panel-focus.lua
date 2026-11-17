-- Where focus goes from the Snacks terminals: a full-screen panel hands window moves to tmux.
-- Driven through the move keys

local t = require('tests.lib.helpers')
local fullscreen_panels = require('core.snacks-nvim.fullscreen-panels')
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

--- @return snacks.win
local function open_panel()
  close_terminals_after()
  return Snacks.terminal.open(
    { 'sleep', '1000' },
    { win = fullscreen_panels.win_config({ position = 'float' }) }
  )
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
