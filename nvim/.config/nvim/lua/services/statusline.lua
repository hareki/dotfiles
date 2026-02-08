---@class services.statusline
local M = {}

---Check if status line is enabled (not disabled by NVIM_NO_STATUS_LINE env var)
---@return boolean enabled True if status line should be shown
function M.have_status_line()
  return vim.env.NVIM_NO_STATUS_LINE == nil
end

---Refresh the lualine statusline if lualine is loaded
---@return nil
function M.refresh()
  if package.loaded['lualine'] then
    local lualine = require('lualine')
    lualine.refresh({ place = { 'statusline' } })
  end
end

return M
