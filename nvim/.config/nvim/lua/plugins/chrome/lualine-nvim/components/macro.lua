---@class plugins.chrome.lualine.components.macro
local M = {}

function M.get()
  local reg = vim.fn.reg_recording()
  return reg
end

function M.cond()
  return vim.fn.reg_recording() ~= ''
end

M.icon = Icons.misc.macro

return M
