--- @class features.navigation.window-navigation.utils
local M = {}

--- @module 'core.snacks-nvim.fullscreen-panels'
local fullscreen_panels = Defer.on_exported_call('core.snacks-nvim.fullscreen-panels')

--- @alias features.navigation.window-navigation.utils.Direction 'left' | 'down' | 'up' | 'right'

--- The `wincmd` key per direction
--- @type table<features.navigation.window-navigation.utils.Direction, string>
local WINCMD_KEYS = { left = 'h', down = 'j', up = 'k', right = 'l' }

--- Go on to the Rex pane in `direction`, when this nvim runs in one
--- @param direction features.navigation.window-navigation.utils.Direction
--- @return nil
local function focus_pane(direction)
  if vim.env.REX_SESSION then
    vim.system({ 'rex', 'focus', direction, '--session', vim.env.REX_SESSION })
  end
end

--- Go to the window in `direction`, or from a window at the edge to the Rex pane there. A
--- full-screen panel covers every window, and `wincmd` leaves a float for a window under it, so
--- with a panel up: a float over the panel goes to the panel, and the panel straight to Rex
--- @param direction features.navigation.window-navigation.utils.Direction
--- @return nil
function M.navigate(direction)
  local panel = fullscreen_panels.visible()

  if not panel then
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(WINCMD_KEYS[direction])

    -- A move that left focus where it was started at the edge
    if win == vim.api.nvim_get_current_win() then
      focus_pane(direction)
    end
    return
  end

  if panel.win ~= vim.api.nvim_get_current_win() then
    panel:focus()
    return
  end

  focus_pane(direction)
end

return M
