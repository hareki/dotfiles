return {
  'folke/lazydev.nvim',
  ft = 'lua',
  opts = function()
    return {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types for vim.uv
        { path = 'snacks.nvim', words = { 'Snacks' } },
      },
    }
  end,
}
