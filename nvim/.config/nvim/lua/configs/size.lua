---@class configs.size.dimensions
---@field width number
---@field height number

---@class configs.size
---@field popup configs.size.popup
---@field side_preview configs.size.side_preview
---@field side_panel configs.size.side_panel
local M = {}

---@class configs.size.popup
---@field lg configs.size.dimensions
---@field sm configs.size.dimensions
---@field width number
---@field height number
M.popup = {
  lg = {
    width = 0.8,
    height = 0.8,
  },

  md = {
    width = 0.65,
    height = 0.65,
  },

  sm = {
    width = 0.5,
    height = 0.5,
  },
}

setmetatable(M.popup, {
  __index = function(_, k)
    return M.popup.lg[k]
  end,
})

---@class configs.size.side_preview
---@field md configs.size.dimensions
---@field width number
---@field height number
M.side_preview = {
  md = {
    width = 0.5,
    height = 0.7,
  },
}

setmetatable(M.side_preview, {
  __index = function(_, k)
    return M.side_preview.md[k]
  end,
})

---@class configs.size.side_panel
---@field md configs.size.dimensions
---@field width number
---@field height number
M.side_panel = {
  md = {
    width = 0.35,
    height = 1,
  },
}

setmetatable(M.side_panel, {
  __index = function(_, k)
    return M.side_panel.md[k]
  end,
})

return M
