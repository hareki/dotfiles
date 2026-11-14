--- @class utils.ui.statusline
local M = {}

--- Refresh the lualine statusline if lualine is loaded
--- @return nil
function M.refresh()
  local lualine = package.loaded['lualine']
  if lualine then
    lualine.refresh({ place = { 'statusline' } })
  end
end

return M
