return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics.virtual_text = true
      opts.inlay_hints.enabled = false
      opts.codelens.enabled = false
      -- opts.document_highlight = true
    end,
  },
}
