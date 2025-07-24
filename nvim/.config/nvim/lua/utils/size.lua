---@class utils.size
local M = {}

---@return integer, integer
function M.screen_size()
  local screen_w = vim.opt.columns:get()
  local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
  return screen_w, screen_h
end

function M.computed_size(size)
  local screen_w, screen_h = M.screen_size()
  local width_in_cols = math.floor(screen_w * size.WIDTH)
  local height_in_rows = math.floor(screen_h * size.HEIGHT)
  return width_in_cols, height_in_rows
end

---@class WinConfig
---@field width    integer
---@field height   integer
---@field col      integer
---@field row      integer
---@param size 'lg' | 'sm' | 'input'
---@param with_border boolean | nil
---@return WinConfig
function M.popup_config(size, with_border)
  local size_configs = require('configs.size')
  local screen_w, screen_h = M.screen_size()
  local window_w, window_h

  if size == 'input' then
    window_w = 60
    window_h = 1
  else
    window_w = math.floor(screen_w * size_configs.popup[size].WIDTH)
    window_h = math.floor(screen_h * size_configs.popup[size].HEIGHT)
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
    row = row,
  }
end

return M
