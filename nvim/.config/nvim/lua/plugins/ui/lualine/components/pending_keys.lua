---@class plugins.ui.lualine.components.pending_keys
local M = {}

function M.keys()
  return '%S'
end

function M.show()
  local result = vim.api.nvim_eval_statusline('%S', {})
  return result.str ~= ''
end

return M
