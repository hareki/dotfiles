---@diagnostic disable: missing-fields

---@class constant.size.Dimensions
---@field WIDTH number
---@field HEIGHT number

---@class constant.size.Popup
---@field lg constant.size.Dimensions
---@field sm constant.size.Dimensions
---@field WIDTH number
---@field HEIGHT number

---@class constant.size.SidePreview
---@field md constant.size.Dimensions
---@field WIDTH number
---@field HEIGHT number

---@class constant.size.SidePanel
---@field md constant.size.Dimensions
---@field WIDTH number
---@field HEIGHT number

---@class constant.size
---@field popup constant.size.Popup
---@field side_preview constant.size.SidePreview
---@field side_panel constant.size.SidePanel
local M = {}

M.popup = {
  lg = {
    WIDTH = 0.8,
    HEIGHT = 0.8,
  },

  sm = {
    WIDTH = 0.5,
    HEIGHT = 0.5,
  },
}

setmetatable(M.popup, {
  __index = function(_, k)
    return M.popup.lg[k]
  end,
})

M.side_preview = {
  md = {
    WIDTH = 0.5,
    HEIGHT = 0.7,
  },
}

setmetatable(M.side_preview, {
  __index = function(_, k)
    return M.side_preview.md[k]
  end,
})

M.side_panel = {
  md = {
    WIDTH = 0.35,
    HEIGHT = 1,
  },
}

setmetatable(M.side_panel, {
  __index = function(_, k)
    return M.side_panel.md[k]
  end,
})

return M
