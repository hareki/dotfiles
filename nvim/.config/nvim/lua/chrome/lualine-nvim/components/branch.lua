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

  local result = branch_name:match('^(CU%-%w+)_.+$')
    or branch_name:match('^.+_(CU%-%w+)$')
    or branch_name

  last_format.branch = branch_name
  last_format.result = result

  return result
end

M.icon = Conf.icons.git.BRANCH

return M
