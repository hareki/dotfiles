---@class constant
---@field YANK_PUT_HL_TIMER number
---@field PREVIEW_TITLE string
local M = {}

M.YANK_PUT_HL_TIMER = 300
M.PREVIEW_TITLE = "Preview"
M.CMP_YANKY_KIND = "Yanky"

M.ESLINT_SUPPORTED = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

M.BRANCH_FORMATS = {
  TASK_ID_ONLY = "task id only",
  TASK_ID_AND_NAME = "task id and name",
  TASK_ID_AND_AUTHOR = "task id and author",
}

return M
