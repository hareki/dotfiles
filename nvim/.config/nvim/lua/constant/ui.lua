---@class constant.ui.PopupDimensions
---@field WIDTH number
---@field HEIGHT number

---@class constant.ui.PopupSize
---@field lg constant.ui.PopupDimensions
---@field xl constant.ui.PopupDimensions
-- Add more size identifiers here if needed, e.g., md, sm, etc.

---@class constant.ui
---@field popup_size constant.ui.PopupSize
local M = {}

M.popup_size = {
  lg = {
    WIDTH = 0.8,
    HEIGHT = 0.8,
  },
  xl = {
    WIDTH = 0.9,
    HEIGHT = 0.9,
  },
}
return M
