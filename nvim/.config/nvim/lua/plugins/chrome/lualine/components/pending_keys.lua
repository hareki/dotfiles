---@class plugins.chrome.lualine.components.pending_keys
local M = {}

function M.get()
  return '%S'
end

function M.cond()
  local result = vim.api.nvim_eval_statusline('%S', {})
  return result.str ~= ''
end

M.icon = Icons.misc.pending_keys

return M
