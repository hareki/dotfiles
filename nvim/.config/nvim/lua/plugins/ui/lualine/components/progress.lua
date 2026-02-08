---@class plugins.ui.lualine.components.progress
local M = {}

---Format progress string with zero-padding and special handling for top/bottom
---@param progress string Raw progress string from lualine (e.g., "50%", "100%", "Top")
---@return string formatted Formatted progress ("50%", "top", etc.)
function M.format(progress)
  local trimmed = progress:match('^%s*(.-)%s*$') or progress
  local digits = trimmed:match('^(%d+)%%%%$')

  if not digits then
    return trimmed:lower()
  end

  if #digits == 1 then
    digits = '0' .. digits
  end

  if digits == '00' then
    return 'top'
  end

  return digits .. '%%'
end

M.icon = Icons.misc.location

return M
