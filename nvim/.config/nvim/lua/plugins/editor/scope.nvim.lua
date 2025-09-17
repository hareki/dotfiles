return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>fB',
      '<cmd>Telescope scope buffers<cr>',
      desc = 'Show All Buffers from All Tabs',
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
