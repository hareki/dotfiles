return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  opts = {
    settings = {
      tsserver_plugins = {
        --TypeScript v4.9+
        '@styled/typescript-styled-plugin',
      },
    },
  },
}
