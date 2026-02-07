---@class config.size.Dimensions
---@field height_offset? number
---@field width_offset? number
---@field height number
---@field width number

---@class config.size
local M = {}

M.popup = {
  full = {
    width = 1,
    height = 1,
    height_offset = -3, -- 2 for the top/bottom borders, 1 for the winbar, we cover the statusline
  },

  lg = {
    width = 0.8,
    height = 0.8,
    min_width = 90,
    min_height = 15,
  },

  vertical_lg = {
    width = 0.6,
    height = 0.8,
    min_width = 10,
    min_height = 15,
  },

  md = {
    width = 0.65,
    height = 0.65,
    min_width = 85,
    min_height = 12,
  },

  sm = {
    width = 0.5,
    height = 0.5,
    min_width = 60,
    min_height = 10,
  },
}

M.side_preview = {
  md = {
    width = 0.5,
    height = 0.7,
    min_width = 80,
    min_height = 15,
  },
}

M.side_panel = {
  md = {
    width = 0.35,
    height = 1,
    min_width = 40,
    min_height = 20,
  },

  lg = {
    width = 0.5,
    height = 1,
    min_width = 40,
    min_height = 20,
  },
}

M.inline_popup = {
  max_height = 0.5,
}

return M
