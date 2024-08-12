return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- We use tiny-inline-diagnostic instead
    -- opts.diagnostics.virtual_text = true
    opts.diagnostics.virtual_text = false

    opts.inlay_hints.enabled = false
    opts.codelens.enabled = false
    -- opts.document_highlight = true
  end,
}
