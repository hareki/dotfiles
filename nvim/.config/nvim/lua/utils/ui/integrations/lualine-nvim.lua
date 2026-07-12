--- @class utils.ui.statusline
local M = {}

--- Check if status line is enabled (not disabled by NVIM_NO_STATUSLINE env var)
--- @return boolean enabled True if status line should be shown
function M.enabled()
  return vim.env.NVIM_NO_STATUSLINE == nil
end

--- Refresh the lualine statusline if lualine is loaded
--- @return nil
function M.refresh()
  if package.loaded['lualine'] then
    local lualine = require('lualine')
    lualine.refresh({ place = { 'statusline' } })
  end
end

return M
