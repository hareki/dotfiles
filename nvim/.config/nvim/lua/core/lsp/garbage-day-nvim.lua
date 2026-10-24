return {
  -- Fork: nvim 0.12 restart fixes + a graceful stop_lsp (force-terminate orphans vtsls's tsserver)
  -- TODO: switch back to Zeioth/garbage-day.nvim once both fixes land upstream
  'hareki/garbage-day.nvim',
  event = 'VeryLazy',
  opts = {},
}
