---@class constant.git
---@field BRANCH_FORMATS table<string, string>
local M = {}

M.BRANCH_FORMATS = {
  TASK_ID_ONLY = "TASK_ID_ONLY",
  TASK_ID_AND_NAME = "TASK_ID_AND_NAME",
  TASK_ID_AND_AUTHOR = "TASK_ID_AND_AUTHOR",
}

return M
