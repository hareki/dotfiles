---@class utils.macro
local M = {}

function M.recording()
  local reg = vim.fn.reg_recording()
  return reg
end

function M.is_recording()
  return vim.fn.reg_recording() ~= ''
end

return M
