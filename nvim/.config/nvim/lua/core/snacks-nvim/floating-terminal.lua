--- The floating terminal: smaller than the screen, so the windows around it stay in reach, and
--- hidden once focus lands in one of them
--- @class core.snacks-nvim.floating-terminal
local M = {}

--- @param self snacks.win
local function hide_on_focus_loss(self)
  -- `show()` recreates this group before calling `on_win`, so nothing piles up
  UI.float.on_focus_loss(self.augroup, function()
    if self:valid() then
      self:hide()
    end
  end)
end

--- @return nil
function M.toggle()
  Snacks.terminal.toggle(nil, { win = { position = 'float', on_win = hide_on_focus_loss } })
end

return M
