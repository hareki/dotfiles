local size_config = require('config.size')

--- @class utils.ui.layout
local M = {}

--- Top-left cell that centers a window of the given size on the screen
--- @param width integer Window width in columns, border excluded
--- @param height integer Window height in rows, border excluded
--- @return integer col
--- @return integer row
function M.center(width, height)
  -- Minus 1 to account for the border
  return math.floor((vim.o.columns - width) / 2) - 1, math.floor((vim.o.lines - height) / 2) - 1
end

--- Resolve a dimensions preset (screen fractions) into whole cells, with offsets and minimums
--- @param dimensions config.size.Dimensions
--- @return integer width Width in columns
--- @return integer height Height in rows
local function resolve_dimensions(dimensions)
  local width = vim.o.columns * dimensions.WIDTH
  local height = vim.o.lines * dimensions.HEIGHT + (dimensions.HEIGHT_OFFSET or 0)

  return math.floor(math.max(width, dimensions.MIN_WIDTH or 0)),
    math.floor(math.max(height, dimensions.MIN_HEIGHT or 0))
end

--- @param variant 'sm' | 'md'
--- @return integer width Width in columns
function M.side_panel_width(variant)
  local panel = size_config.side_panel[variant]

  return math.floor(math.max(vim.o.columns * panel.WIDTH, panel.MIN_WIDTH))
end

--- The side preview float: left of the side panel, centered, 3 columns off, in `relative = 'win'`
--- coordinates; a plugin measuring col from the panel's right edge (trouble) subtracts its width
--- @return { width: integer, height: integer, row: integer, col: integer } geometry
function M.side_preview()
  local width, height = resolve_dimensions(size_config.side_preview)
  local _, row = M.center(width, height)

  return { width = width, height = height, row = row, col = -width - 3 }
end

--- Height cap for inline popups; pass the function itself so it follows terminal resizes
--- @return integer max_height Height in rows
function M.inline_max_height()
  return math.floor(vim.o.lines * size_config.inline_popup.MAX_HEIGHT)
end

--- Width counterpart of M.inline_max_height
--- @return integer max_width Width in columns
function M.inline_max_width()
  return math.floor(vim.o.columns * size_config.inline_popup.MAX_WIDTH)
end

--- @class utils.ui.layout.WinConfig
--- @field width    integer
--- @field height   integer
--- @field col      integer
--- @field row      integer

--- Compute a centered window configuration from a size preset
--- @param size config.size.PopupPreset
--- @return utils.ui.layout.WinConfig config
function M.popup(size)
  local preset = size_config.popup[size]
  local width, height = resolve_dimensions(preset)
  local col, row = M.center(width, height)

  return { width = width, height = height, col = col, row = row + (preset.ROW_OFFSET or 0) }
end

--- @class utils.ui.layout.WinConfigFn
--- @field width  fun(): integer
--- @field height fun(): integer
--- @field col    fun(): integer
--- @field row    fun(): integer

--- Like M.popup, but function-valued, so consumers size and center popups at open time, after
--- any terminal resize (Snacks can't take callable max_width/max_height, so set no max fields)
--- @param size config.size.PopupPreset
--- @return utils.ui.layout.WinConfigFn config Window config resolved per call
function M.popup_fn(size)
  return {
    width = function()
      return M.popup(size).width
    end,
    height = function()
      return M.popup(size).height
    end,
    col = function()
      return M.popup(size).col
    end,
    row = function()
      return M.popup(size).row
    end,
  }
end

--- Like M.popup_fn, for a snacks picker layout: 2 more cells, as its size counts inner borders
--- @param size config.size.PopupPreset
--- @return utils.ui.layout.WinConfigFn config Window config resolved per call
function M.picker_fn(size)
  local config = M.popup_fn(size)

  return {
    width = function()
      return config.width() + 2
    end,
    height = function()
      return config.height() + 2
    end,
    col = config.col,
    row = config.row,
  }
end

return M
