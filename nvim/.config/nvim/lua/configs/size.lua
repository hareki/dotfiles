---@class configs.size.dimensions
---@field width number
---@field height number
---@field min_width? number
---@field min_height? number

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
  full = {
    width = vim.opt.columns:get(),
    height = vim.opt.lines:get() - 4, -- 2 for the top and bottom borders, 2 for winbar and statusline
  },

  lg = {
    width = 0.8,
    height = 0.8,
    min_width = 100,
    min_height = 20,
  },

  md = {
    width = 0.65,
    height = 0.65,
    min_width = 80,
    min_height = 15,
  },

  sm = {
    width = 0.5,
    height = 0.5,
    min_width = 60,
    min_height = 10,
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
    min_width = 80,
    min_height = 15,
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
    min_width = 40,
    min_height = 20,
  },
}

setmetatable(M.side_panel, {
  __index = function(_, k)
    return M.side_panel.md[k]
  end,
})

return M
