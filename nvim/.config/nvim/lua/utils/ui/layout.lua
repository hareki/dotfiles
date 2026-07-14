--- @class utils.ui.layout
local M = {}

--- Generate telescope layout configuration for a given size preset
--- @param size 'sm' | 'md' | 'lg' | 'vertical_lg' | 'full' Size preset name
--- @return table layout Layout config with size hint, height, and width functions
function M.telescope(size)
  return {
    size = size, -- Hint to calculate the position
    height = function()
      return M.popup(size, true).height
    end,
    width = function()
      return M.popup(size, true).width
    end,
  }
end

--- Get the current screen dimensions in columns and rows
--- @return integer screen_w Screen width in columns
--- @return integer screen_h Screen height in rows
function M.screen_size()
  local screen_w = vim.o.columns
  local screen_h = vim.o.lines

  return screen_w, screen_h
end

local computed_input_size = {
  height = 1,
  width = 60,
}

--- Resolve a dimensions preset into whole width/height cells: fractions of the
--- screen when <= 1, absolute values otherwise, then offsets and minimums
--- @param dimensions config.size.Dimensions
--- @return integer width Width in columns
--- @return integer height Height in rows
local function resolve_dimensions(dimensions)
  local screen_w, screen_h = M.screen_size()

  local width = dimensions.WIDTH <= 1 and screen_w * dimensions.WIDTH or dimensions.WIDTH
  local height = dimensions.HEIGHT <= 1 and screen_h * dimensions.HEIGHT or dimensions.HEIGHT

  local width_offset = dimensions.WIDTH_OFFSET
  if width_offset then
    width = math.max(width + width_offset, 1)
  end

  local height_offset = dimensions.HEIGHT_OFFSET
  if height_offset then
    height = math.max(height + height_offset, 1)
  end

  local min_width = dimensions.MIN_WIDTH
  if min_width and width < min_width then
    width = min_width
  end

  local min_height = dimensions.MIN_HEIGHT
  if min_height and height < min_height then
    height = min_height
  end

  return math.floor(width), math.floor(height)
end

--- Compute actual dimensions from a size configuration
--- @param size config.size.Dimensions | 'input' Size config or 'input' preset
--- @param with_border? boolean Whether to add 2 for border (default false)
--- @return integer width Width in columns
--- @return integer height Height in rows
function M.compute_size(size, with_border)
  local width_in_cols, height_in_rows

  if size == 'input' then
    width_in_cols = computed_input_size.width
    height_in_rows = computed_input_size.height
  else
    width_in_cols, height_in_rows = resolve_dimensions(size --[[@as config.size.Dimensions]])
  end

  return width_in_cols + (with_border and 2 or 0), height_in_rows + (with_border and 2 or 0)
end

--- Compute width/height for a side panel or side preview size preset
--- @param category 'side_panel' | 'side_preview' Size category in config.size
--- @param variant 'sm' | 'md' | 'lg' Variant key within the category
--- @param with_border? boolean Whether to add 2 for border (default false)
--- @return integer width Width in columns
--- @return integer height Height in rows
function M.side_size(category, variant, with_border)
  return M.compute_size(Conf.size[category][variant], with_border)
end

--- @class utils.ui.layout.WinConfig
--- @field width    integer
--- @field height   integer
--- @field col      integer
--- @field row      integer

--- Compute a centered window configuration from a size preset
--- @param size 'lg' | 'md' | 'sm' | 'input' | 'full' | 'vertical_lg' Size preset name
--- @param with_border boolean | nil Whether to add 2 for border (default false)
--- @return utils.ui.layout.WinConfig config Window config with width, height, col, row
function M.popup(size, with_border)
  local screen_w, screen_h = M.screen_size()
  local window_w, window_h

  if size == 'input' then
    window_w = computed_input_size.width
    window_h = computed_input_size.height
  else
    window_w, window_h = resolve_dimensions(Conf.size.popup[size])
  end

  -- Minus 1 to account for the border
  local col = math.floor((screen_w - window_w) / 2) - 1
  local row = math.floor((screen_h - window_h) / 2) - 1

  return {
    -- Some plugins like telescope takes the border into account for the size when rendering the popup
    -- In that case, we should add 2 to the width and height to maintain the same size with the others that do not
    width = window_w + (with_border and 2 or 0),
    height = window_h + (with_border and 2 or 0),
    col = col,
    row = row - (size == 'full' and 1 or 0), -- Off center by one row for full screen to cover the winbar
  }
end

--- @class utils.ui.layout.WinConfigFn
--- @field width  fun(): integer
--- @field height fun(): integer
--- @field col    fun(): integer
--- @field row    fun(): integer

--- Like M.popup, but with function-valued fields the consumer resolves at
--- window-open time, so popups opened after a terminal resize are sized and
--- centered against the current screen instead of the startup one. Snacks
--- resolves callables for width/height/col/row; its max_width/max_height do
--- not support callables, so pair these with no max fields
--- @param size 'lg' | 'md' | 'sm' | 'input' | 'full' | 'vertical_lg' Size preset name
--- @param with_border boolean | nil Whether to add 2 for border (default false)
--- @return utils.ui.layout.WinConfigFn config Window config resolved per call
function M.popup_fn(size, with_border)
  return {
    width = function()
      return M.popup(size, with_border).width
    end,
    height = function()
      return M.popup(size, with_border).height
    end,
    col = function()
      return M.popup(size, with_border).col
    end,
    row = function()
      return M.popup(size, with_border).row
    end,
  }
end

return M
