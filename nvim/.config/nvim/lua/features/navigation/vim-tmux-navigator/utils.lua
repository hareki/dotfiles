--- @class features.navigation.vim-tmux-navigator.utils
local M = {}

--- @module 'core.snacks-nvim.fullscreen-panels'
local fullscreen_panels = Defer.on_exported_call('core.snacks-nvim.fullscreen-panels')

--- @alias features.navigation.vim-tmux-navigator.utils.Direction 'left' | 'down' | 'up' | 'right'

--- The plugin's command and tmux's `select-pane` flag per direction
--- @type table<features.navigation.vim-tmux-navigator.utils.Direction, { command: string, flag: string }>
local DIRECTIONS = {
  left = { command = 'TmuxNavigateLeft', flag = '-L' },
  down = { command = 'TmuxNavigateDown', flag = '-D' },
  up = { command = 'TmuxNavigateUp', flag = '-U' },
  right = { command = 'TmuxNavigateRight', flag = '-R' },
}

--- Go to the window or tmux pane in `direction`. A full-screen panel covers every window, and the
--- plugin's `wincmd` leaves a float for the window under it, so a panel goes straight to tmux
--- @param direction features.navigation.vim-tmux-navigator.utils.Direction
--- @return nil
function M.navigate(direction)
  local target = DIRECTIONS[direction]

  if not fullscreen_panels.is_focused() then
    vim.cmd(target.command)
    return
  end

  if vim.env.TMUX then
    -- What the plugin sends from a window at the edge, `-Z` being its tmux_navigator_preserve_zoom
    vim.system({ 'tmux', 'select-pane', '-t', vim.env.TMUX_PANE, target.flag, '-Z' })
  end
end

return M
