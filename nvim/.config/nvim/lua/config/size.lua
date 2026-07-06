--- @class config.size.Dimensions
--- @field HEIGHT_OFFSET? number
--- @field WIDTH_OFFSET? number
--- @field HEIGHT number
--- @field WIDTH number

--- @class config.size
local M = {}

M.popup = {
  full = {
    WIDTH = 1,
    HEIGHT = 1,
    HEIGHT_OFFSET = -3, -- 2 for the top/bottom borders, 1 for the winbar, we cover the statusline
  },

  lg = {
    WIDTH = 0.8,
    HEIGHT = 0.8,
    MIN_WIDTH = 90,
    MIN_HEIGHT = 15,
  },

  vertical_lg = {
    WIDTH = 0.45,
    HEIGHT = 0.8,
    MIN_WIDTH = 60,
    MIN_HEIGHT = 15,
  },

  md = {
    WIDTH = 0.65,
    HEIGHT = 0.65,
    MIN_WIDTH = 85,
    MIN_HEIGHT = 12,
  },

  sm = {
    WIDTH = 0.5,
    HEIGHT = 0.5,
    MIN_WIDTH = 60,
    MIN_HEIGHT = 10,
  },
}

M.side_preview = {
  md = {
    WIDTH = 0.5,
    HEIGHT = 0.7,
    MIN_WIDTH = 80,
    MIN_HEIGHT = 15,
  },
}

M.side_panel = {
  sm = {
    WIDTH = 0.3,
    HEIGHT = 1,
    MIN_WIDTH = 35,
    MIN_HEIGHT = 20,
  },
  md = {
    WIDTH = 0.35,
    HEIGHT = 1,
    MIN_WIDTH = 40,
    MIN_HEIGHT = 20,
  },

  lg = {
    WIDTH = 0.5,
    HEIGHT = 1,
    MIN_WIDTH = 40,
    MIN_HEIGHT = 20,
  },
}

M.inline_popup = {
  MAX_HEIGHT = 0.5,
}

return M
