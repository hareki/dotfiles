---@class plugins.ui.lualine.components.repo_name
local M = {}

function M.get()
  local utils = require('utils.git')
  return utils.get_repo_name()
end

M.icon = Icons.explorer.folder

return M
