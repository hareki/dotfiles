-- Diagnostics UX: how they display, and the jumps between them
local map = vim.keymap.set

vim.diagnostic.config({
  severity_sort = true,
  float = {
    border = 'rounded',
    source = true,
  },
  signs = {
    -- Blank sign text: the number column carries the highlight, through numhl
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '',
      [vim.diagnostic.severity.INFO] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
  },
  -- Every jump opens the line's diagnostics, Neovim's own count-aware ]d/[d/]D/[D (titled in
  -- config/keymap-registry.lua) included; on_jump runs scheduled, and only once the jump succeeded
  jump = {
    on_jump = function()
      vim.cmd.EagleWinLineDiagnostic()
    end,
  },
})

--- @param next boolean
--- @param severity 'ERROR' | 'WARN' | 'INFO'
local function jump_to(next, severity)
  local direction = next and 1 or -1
  local level = vim.diagnostic.severity[severity]

  return function()
    vim.diagnostic.jump({ severity = level, count = direction * vim.v.count1 })
  end
end

map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']e', jump_to(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', jump_to(false, 'ERROR'), { desc = 'Previous Error' })
map('n', ']w', jump_to(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', jump_to(false, 'WARN'), { desc = 'Previous Warning' })
map('n', ']i', jump_to(true, 'INFO'), { desc = 'Next Info' })
map('n', '[i', jump_to(false, 'INFO'), { desc = 'Previous Info' })
