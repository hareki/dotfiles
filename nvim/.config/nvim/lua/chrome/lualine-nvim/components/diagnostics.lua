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

-- vim.diagnostic.get() copies every diagnostic and the statusline re-evaluates on
-- every redraw. A single slot is enough: with globalstatus the statusline only
-- renders the current buffer, so almost all redraws hit the same buffer back to
-- back, and a per-buffer map would just accumulate entries that are never re-read.
--- @class chrome.lualine.components.diagnostics.Cache
--- @field buf integer
--- @field counts { error: integer, warn: integer, info: integer, hint: integer } | nil
local cache = { buf = -1, counts = nil }

local group = vim.api.nvim_create_augroup('chrome.lualine.diagnostics-cache', { clear = true })
vim.api.nvim_create_autocmd('DiagnosticChanged', {
  group = group,
  callback = function(event)
    if event.buf == cache.buf then
      cache.buf = -1
      cache.counts = nil
    end
  end,
})
-- Wiped buffer numbers can be reused; drop the slot so a new buffer with the
-- same number can't inherit stale counts
vim.api.nvim_create_autocmd('BufWipeout', {
  group = group,
  callback = function(event)
    if event.buf == cache.buf then
      cache.buf = -1
      cache.counts = nil
    end
  end,
})

--- Count diagnostics for the current buffer, excluding the synthetic
--- 'underline-hack' duplicates injected by diagnostic-underline-hack so
--- they don't inflate the displayed counts.
--- @return { error: integer, warn: integer, info: integer, hint: integer }
local function filtered_counts()
  local bufnr = vim.api.nvim_get_current_buf()
  if cache.buf == bufnr and cache.counts then
    return cache.counts
  end

  local counts = { error = 0, warn = 0, info = 0, hint = 0 }

  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
    if diagnostic.source ~= 'underline-hack' then
      local name = SEVERITY_NAMES[diagnostic.severity]
      if name then
        counts[name] = counts[name] + 1
      end
    end
  end

  cache.buf = bufnr
  cache.counts = counts

  return counts
end

M.sources = { filtered_counts }

return M
