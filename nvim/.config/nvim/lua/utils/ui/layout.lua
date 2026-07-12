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
    local screen_w, screen_h = M.screen_size()

    width_in_cols = math.floor(screen_w * size.WIDTH)
    height_in_rows = math.floor(screen_h * size.HEIGHT)
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
    local dimensions = Conf.size.popup[size]
    if dimensions.WIDTH <= 1 then
      window_w = math.floor(screen_w * dimensions.WIDTH)
    else
      window_w = dimensions.WIDTH
    end

    if dimensions.HEIGHT <= 1 then
      window_h = math.floor(screen_h * dimensions.HEIGHT)
    else
      window_h = dimensions.HEIGHT
    end

    if dimensions.WIDTH_OFFSET then
      window_w = math.max(window_w + dimensions.WIDTH_OFFSET, 1)
    end

    if dimensions.HEIGHT_OFFSET then
      window_h = math.max(window_h + dimensions.HEIGHT_OFFSET, 1)
    end

    if dimensions.MIN_WIDTH and window_w < dimensions.MIN_WIDTH then
      window_w = dimensions.MIN_WIDTH
    end

    if dimensions.MIN_HEIGHT and window_h < dimensions.MIN_HEIGHT then
      window_h = dimensions.MIN_HEIGHT
    end
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

return M
