--- @class chrome.lualine.components.diagnostics
local M = {}

M.symbols = {
  error = Conf.Icons.diagnostics.Error,
  warn = Conf.Icons.diagnostics.Warn,
  info = Conf.Icons.diagnostics.Info,
  hint = Conf.Icons.diagnostics.Hint,
}

M.sections = { 'error', 'warn', 'info' }

return M
