return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.diagnostics.virtual_text = false -- We use tiny-inline-diagnostic instead (currently disable it as well)
    opts.inlay_hints.enabled = false
    opts.codelens.enabled = false
    -- opts.document_highlight = true

    -- Use noice.nvim to do this instead, just keep it commented as a reference
    -- opts.setup["*"] = function(client, bufnr)
    --   vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    --     border = "rounded",
    --   })
    -- end
  end,
}
