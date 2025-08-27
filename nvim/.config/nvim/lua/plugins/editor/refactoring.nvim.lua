return {
  'hareki/refactoring.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {},
  config = function(_, opts)
    require('refactoring').setup(opts)
    require('telescope').load_extension('refactoring')
  end,
}
