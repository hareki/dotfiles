---@class constant.git
---@field branch_formats table<string, string>
local M = {}

M.branch_formats = {
  TASK_ID_ONLY = 'TASK_ID_ONLY',
  TASK_ID_AND_NAME = 'TASK_ID_AND_NAME',
  TASK_ID_AND_AUTHOR = 'TASK_ID_AND_AUTHOR',
}

return M
