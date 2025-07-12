---@class util.telescope
local M = {}
---@param size 'sm' | 'lg'
function M.layout_config(size)
  return {
    size = size, -- Hint to calculate the position
    height = function()
      return Util.ui.get_float_config(size, true).height
    end,
    width = function()
      return Util.ui.get_float_config(size, true).width
    end,
  }
end

return M
