--- @class chrome.lualine.components.diagnostics
local M = {}

M.symbols = {
  error = Conf.Icons.diagnostics.Error,
  warn = Conf.Icons.diagnostics.Warn,
  info = Conf.Icons.diagnostics.Info,
  hint = Conf.Icons.diagnostics.Hint,
}

M.sections = { 'error', 'warn', 'info' }

local SEVERITY_NAMES = {
  [vim.diagnostic.severity.ERROR] = 'error',
  [vim.diagnostic.severity.WARN] = 'warn',
  [vim.diagnostic.severity.INFO] = 'info',
  [vim.diagnostic.severity.HINT] = 'hint',
}

--- Count diagnostics for the current buffer, excluding the synthetic
--- 'underline-hack' duplicates injected by diagnostic_underline_hack so
--- they don't inflate the displayed counts.
--- @return { error: integer, warn: integer, info: integer, hint: integer }
local function filtered_counts()
  local counts = { error = 0, warn = 0, info = 0, hint = 0 }

  for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
    if diagnostic.source ~= 'underline-hack' then
      local name = SEVERITY_NAMES[diagnostic.severity]
      if name then
        counts[name] = counts[name] + 1
      end
    end
  end

  return counts
end

M.sources = { filtered_counts }

return M
