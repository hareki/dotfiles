--- @class chrome.lualine.components.diagnostics
local M = {}

M.symbols = {
  error = Conf.icons.diagnostics.ERROR,
  warn = Conf.icons.diagnostics.WARN,
  info = Conf.icons.diagnostics.INFO,
}

M.sections = { 'error', 'warn', 'info' }

-- The statusline redraws constantly, so even vim.diagnostic.count()'s store walk is cached. One
-- slot suffices: globalstatus renders only the current buffer, so a per-buffer map would just grow
--- @class chrome.lualine.components.diagnostics.Cache
--- @field buf integer -1 while the slot is empty
--- @field counts { error: integer?, warn: integer?, info: integer? } lualine reads a missing count as 0
local cache = { buf = -1, counts = {} }

vim.api.nvim_create_autocmd('DiagnosticChanged', {
  group = vim.api.nvim_create_augroup('chrome.lualine.diagnostics-cache', { clear = true }),
  callback = function(event)
    if event.buf == cache.buf then
      cache.buf = -1
    end
  end,
})

--- Count the current buffer's diagnostics of the M.sections severities
--- @return { error: integer?, warn: integer?, info: integer? }
local function cached_counts()
  local bufnr = vim.api.nvim_get_current_buf()
  if cache.buf == bufnr then
    return cache.counts
  end

  local counts = vim.diagnostic.count(bufnr)
  local severity = vim.diagnostic.severity
  cache.buf = bufnr
  cache.counts = {
    error = counts[severity.ERROR],
    warn = counts[severity.WARN],
    info = counts[severity.INFO],
  }

  return cache.counts
end

M.sources = { cached_counts }

return M
