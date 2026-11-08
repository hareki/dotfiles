--- @class chrome.lualine-nvim.components.harpoon
local M = {}

--- The status `cond` computed for this draw: lualine calls `cond` right before `update_status`, so
--- `get` reads it back instead of asking the feature twice (harpoon:list() does a getcwd syscall)
--- @type string | nil
local text

--- @return boolean has_pinned_files
function M.cond()
  local harpoon_utils = require('features.navigation.harpoon.utils')
  text = harpoon_utils.status()
  return text ~= nil
end

--- @return string | nil formatted as "1 [3] 4" or nil if the pin list is empty
function M.get()
  return text
end

M.icon = Conf.icons.tools.PIN
M.color = 'yellow'

return M
