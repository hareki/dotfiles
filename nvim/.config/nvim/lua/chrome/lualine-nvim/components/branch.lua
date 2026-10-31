--- @class chrome.lualine.components.branch
local M = {}

-- Single-slot memo: the statusline re-formats the same branch on every redraw
local last_format = { branch = nil, result = nil }

--- Shorten a ClickUp branch (`CU-<id>_<task>` or `<task>_CU-<id>`) to its CU-ID, others unchanged
--- @param branch_name string
--- @return string formatted
function M.format(branch_name)
  if last_format.branch == branch_name then
    return last_format.result
  end

  local prefix
  local remaining

  if branch_name:match('^CU%-%w+') then
    prefix, remaining = branch_name:match('^(CU%-%w+)_(.+)$')
  else
    remaining, prefix = branch_name:match('^(.*)_(CU%-%w+)$')
  end

  local result = (prefix and remaining ~= '') and prefix or branch_name
  last_format.branch = branch_name
  last_format.result = result

  return result
end

M.icon = Conf.icons.git.BRANCH

return M
