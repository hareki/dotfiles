return {
  'folke/lazydev.nvim',
  ft = 'lua',
  opts = function()
    return {
      library = {
        { path = 'snacks.nvim', words = { 'Snacks' } },
      },
    }
  end,
}
