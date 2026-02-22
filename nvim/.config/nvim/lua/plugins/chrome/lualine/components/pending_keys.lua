---@class plugins.chrome.lualine.components.pending_keys
local M = {}

-- Called via `%{v:lua...}` on every statusline redraw, bypassing lualine's
-- refresh timer so count prefixes (e.g. "14" in "14j") appear immediately.
---@private
---@return string
function M._render()
  local result = vim.api.nvim_eval_statusline('%S', {})
  if result.str ~= '' then
    return Icons.misc.pending_keys .. ' ' .. result.str
  end
  return ''
end

function M.get()
  return "%{v:lua.require'plugins.chrome.lualine.components.pending_keys'._render()}"
end

return M
