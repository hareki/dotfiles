return {
  opts = {
    on_attach = function(client, bufnr)
      local lsp_utils = require('plugins.lsp.nvim-lspconfig.utils')
      lsp_utils.populate_workspace_diagnostics(client, bufnr)
    end,

    settings = {
      Lua = {
        diagnostics = {
          unusedLocalExclude = { '_*' }, -- ignore _foo, _bar, _
        },
      },
    },
  },
}
