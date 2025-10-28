return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>fB',
      function()
        require('plugins.ui.snacks.scope_snacks').buffers()
      end,
      desc = 'Find All Buffers',
    },
  },
  config = function()
    require('scope').setup()
    -- Defer loading the Telescope extension until Telescope itself loads
    require('utils.package').on_load('telescope.nvim', function()
      pcall(function()
        require('telescope').load_extension('scope')
      end)
    end)
  end,
}
