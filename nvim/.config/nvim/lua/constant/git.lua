---@class constant.git
---@field BRANCH_FORMATS table<string, string>
local M = {}

M.BRANCH_FORMATS = {
  TASK_ID_ONLY = "task id only",
  TASK_ID_AND_NAME = "task id and name",
  TASK_ID_AND_AUTHOR = "task id and author",
}

return M
