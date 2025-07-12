---@class util.ui
local M = {}

---@class WinConfig
---@field width    integer
---@field height   integer
---@field col      integer
---@field row      integer
---@field screen_h integer
---@field screen_w integer
---@param size 'lg' | 'sm' | 'input'
---@param with_border boolean | nil
---@return WinConfig
function M.get_float_config(size, with_border)
  local screen_w = vim.opt.columns:get()
  local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
  local window_w, window_h

  if size == 'input' then
    window_w = 60
    window_h = 1
  else
    window_w = math.floor(screen_w * Constant.ui.popup_size[size].WIDTH)
    window_h = math.floor(screen_h * Constant.ui.popup_size[size].HEIGHT)
  end

  -- local window_w = math.floor(screen_w * Constant.ui.popup_size[size].WIDTH)
  -- local window_h = math.floor(screen_h * Constant.ui.popup_size[size].HEIGHT)

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
    screen_h = screen_h,
    screen_w = screen_w,
  }
end

return M
