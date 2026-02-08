---@class plugins.ui.lualine.components.branch
local M = {}

function M.format(branch_name)
  local utils = require('utils.git')
  return utils.format_branch_name(branch_name)
end

M.icon = Icons.git.branch

return M
