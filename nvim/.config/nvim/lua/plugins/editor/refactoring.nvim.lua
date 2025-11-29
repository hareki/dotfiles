return {
  'hareki/refactoring.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {},
  config = function(_, opts)
    require('refactoring').setup(opts)

    package_utils = require('utils.package')
    package_utils.on_load('telescope.nvim', function()
      require('telescope').load_extension('refactoring')
    end)
  end,
}
