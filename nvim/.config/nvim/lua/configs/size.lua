---@class configs.size.dimensions
---@field WIDTH number
---@field HEIGHT number

---@class configs.size
---@field popup configs.size.popup
---@field side_preview configs.size.side_preview
---@field side_panel configs.size.side_panel
local M = {}

---@class configs.size.popup
---@field lg configs.size.dimensions
---@field sm configs.size.dimensions
---@field WIDTH number
---@field HEIGHT number
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

---@class configs.size.side_preview
---@field md configs.size.dimensions
---@field WIDTH number
---@field HEIGHT number
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

---@class configs.size.side_panel
---@field md configs.size.dimensions
---@field WIDTH number
---@field HEIGHT number
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
