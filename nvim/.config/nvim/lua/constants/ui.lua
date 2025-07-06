---@class constant.ui.PopupDimensions
---@field WIDTH number
---@field HEIGHT number
---@class constant.ui.PopupSize
---@field lg constant.ui.PopupDimensions
---@field sm constant.ui.PopupDimensions
---@class constant.ui
---@field popup_size constant.ui.PopupSize
local M = {}

M.popup_size = {
  lg = {
    WIDTH = 0.8,
    HEIGHT = 0.8,
  },

  sm = {
    WIDTH = 0.5,
    HEIGHT = 0.5,
  },
}
return M
