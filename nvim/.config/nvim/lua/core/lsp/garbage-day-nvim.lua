return {
  -- Fork of Zeioth/garbage-day.nvim carrying the nvim 0.12 restart fixes (upstream
  -- PR #23) plus a graceful stop_lsp: force-terminate SIGTERMs the server mid-handshake
  -- and orphans vtsls's forked tsserver (PID-1, up to 3GB heap) on every focus cycle
  -- TODO: back to mainstream once both fixes land there
  'hareki/garbage-day.nvim',
  event = 'VeryLazy',
  opts = {},
}
