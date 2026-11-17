--- The floating terminal: smaller than the screen, so the windows around it stay in reach, and
--- hidden once focus lands in one of them
--- @class core.snacks-nvim.floating-terminal
local M = {}

--- @module 'core.snacks-nvim.fullscreen-panels'
local fullscreen_panels = Defer.on_exported_call('core.snacks-nvim.fullscreen-panels')

--- @param self snacks.win
local function hide_on_focus_loss(self)
  local function hide()
    if self:valid() then
      self:hide()
    end
  end

  -- `show()` recreates this group before calling `on_win`, so nothing piles up
  UI.float.on_focus_loss(self.augroup, hide)
  -- Opened over a full-screen panel, the window around it is that panel
  fullscreen_panels.on_focus_return(self.augroup, hide)
end

--- @return nil
function M.toggle()
  Snacks.terminal.toggle(nil, { win = { position = 'float', on_win = hide_on_focus_loss } })
end

return M
