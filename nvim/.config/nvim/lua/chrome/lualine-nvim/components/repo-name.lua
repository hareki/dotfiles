--- @class chrome.lualine.components.repo-name
local M = {}

function M.get()
  local utils = require('utils.git')
  return utils.get_repo_name()
end

M.icon = Conf.icons.file_tree.FOLDER

return M
