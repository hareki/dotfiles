--- @class chrome.lualine.components.diagnostics
local M = {}

M.symbols = {
  error = Conf.icons.diagnostics.ERROR,
  warn = Conf.icons.diagnostics.WARN,
  info = Conf.icons.diagnostics.INFO,
  hint = Conf.icons.diagnostics.HINT,
}

M.sections = { 'error', 'warn', 'info' }

local SEVERITY_NAMES = {
  [vim.diagnostic.severity.ERROR] = 'error',
  [vim.diagnostic.severity.WARN] = 'warn',
  [vim.diagnostic.severity.INFO] = 'info',
  [vim.diagnostic.severity.HINT] = 'hint',
}

-- The statusline redraws constantly, so even vim.diagnostic.count()'s store walk is cached. One
-- slot suffices: globalstatus renders only the current buffer, so a per-buffer map would just grow
--- @class chrome.lualine.components.diagnostics.Cache
--- @field buf integer -1 while the slot is empty
--- @field counts { error: integer, warn: integer, info: integer, hint: integer }
local cache = { buf = -1, counts = { error = 0, warn = 0, info = 0, hint = 0 } }

vim.api.nvim_create_autocmd('DiagnosticChanged', {
  group = vim.api.nvim_create_augroup('chrome.lualine.diagnostics-cache', { clear = true }),
  callback = function(event)
    if event.buf == cache.buf then
      cache.buf = -1
    end
  end,
})

--- Count diagnostics for the current buffer.
--- @return { error: integer, warn: integer, info: integer, hint: integer }
local function cached_counts()
  local bufnr = vim.api.nvim_get_current_buf()
  if cache.buf == bufnr then
    return cache.counts
  end

  local counts = { error = 0, warn = 0, info = 0, hint = 0 }

  for severity, count in pairs(vim.diagnostic.count(bufnr)) do
    local name = SEVERITY_NAMES[severity]
    if name then
      counts[name] = count
    end
  end

  cache.buf = bufnr
  cache.counts = counts

  return counts
end

M.sources = { cached_counts }

return M
