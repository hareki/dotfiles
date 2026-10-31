--- @class utils.ui.layout
local M = {}

--- The config.size.popup presets plus 'input', which is sized here
--- @alias utils.ui.layout.PopupSize config.size.PopupPreset | 'input'

--- Top-left cell that centers a window of the given size on the screen
--- @param width integer Window width in columns, border excluded
--- @param height integer Window height in rows, border excluded
--- @return integer col
--- @return integer row
function M.center(width, height)
  -- Minus 1 to account for the border
  return math.floor((vim.o.columns - width) / 2) - 1, math.floor((vim.o.lines - height) / 2) - 1
end

local computed_input_size = {
  height = 1,
  width = 60,
}

--- Resolve a dimensions preset (screen fractions) into whole cells, with offsets and minimums
--- @param dimensions config.size.Dimensions
--- @return integer width Width in columns
--- @return integer height Height in rows
local function resolve_dimensions(dimensions)
  local width = vim.o.columns * dimensions.WIDTH
  local height = vim.o.lines * dimensions.HEIGHT

  local height_offset = dimensions.HEIGHT_OFFSET
  if height_offset then
    height = math.max(height + height_offset, 1)
  end

  return math.floor(math.max(width, dimensions.MIN_WIDTH or 0)),
    math.floor(math.max(height, dimensions.MIN_HEIGHT or 0))
end

--- Compute width/height for a side panel or side preview size preset
--- @overload fun(category: 'side_panel', variant: 'sm'|'md'): integer, integer
--- @overload fun(category: 'side_preview', variant: 'md'): integer, integer
--- @param category 'side_panel' | 'side_preview' Size category in config.size
--- @param variant string Variant key within the category
--- @return integer width Width in columns
--- @return integer height Height in rows
function M.side_size(category, variant)
  return resolve_dimensions(Conf.size[category][variant])
end

--- Geometry of the side preview float: left of the side panel, centered, with a 3-column gap
--- @return { width: integer, height: integer, row: integer, col: integer } geometry
function M.side_preview()
  local width, height = M.side_size('side_preview', 'md')
  local _, row = M.center(width, height)

  return { width = width, height = height, row = row, col = -width - 3 }
end

--- Height cap for inline popups; pass the function itself so it follows terminal resizes
--- @return integer max_height Height in rows
function M.inline_max_height()
  return math.floor(vim.o.lines * Conf.size.inline_popup.MAX_HEIGHT)
end

--- Width counterpart of M.inline_max_height
--- @return integer max_width Width in columns
function M.inline_max_width()
  return math.floor(vim.o.columns * Conf.size.inline_popup.MAX_WIDTH)
end

--- @class utils.ui.layout.WinConfig
--- @field width    integer
--- @field height   integer
--- @field col      integer
--- @field row      integer

--- Compute a centered window configuration from a size preset
--- @param size utils.ui.layout.PopupSize
--- @return utils.ui.layout.WinConfig config
function M.popup(size)
  local window_w, window_h
  local preset = Conf.size.popup[size] -- nil for 'input'

  if size == 'input' then
    window_w = computed_input_size.width
    window_h = computed_input_size.height
  else
    window_w, window_h = resolve_dimensions(preset)
  end

  local col, row = M.center(window_w, window_h)

  return {
    width = window_w,
    height = window_h,
    col = col,
    row = row + (preset and preset.ROW_OFFSET or 0),
  }
end

--- @class utils.ui.layout.WinConfigFn
--- @field width  fun(): integer
--- @field height fun(): integer
--- @field col    fun(): integer
--- @field row    fun(): integer

--- Like M.popup, but function-valued, so consumers size and center popups at open time, after
--- any terminal resize (Snacks can't take callable max_width/max_height, so set no max fields)
--- @param size utils.ui.layout.PopupSize
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
--- @param size utils.ui.layout.PopupSize
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
