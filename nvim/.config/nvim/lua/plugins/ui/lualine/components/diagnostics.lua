---@class plugins.ui.lualine.components.diagnostics
local M = {}

M.symbols = {
  error = Icons.diagnostics.Error,
  warn = Icons.diagnostics.Warn,
  info = Icons.diagnostics.Info,
  hint = Icons.diagnostics.Hint,
}

M.sections = { 'error', 'warn', 'info' }

return M
