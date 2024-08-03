---@class CommonUtil
local M = {}

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

M.aucmd = vim.api.nvim_create_autocmd

M.map = vim.keymap.set
M.unmap = vim.keymap.del

return M
