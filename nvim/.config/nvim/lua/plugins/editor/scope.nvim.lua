return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>fB',
      '<cmd>Telescope scope buffers<cr>',
      desc = 'Show All Buffrs from All Tabs',
    },
  },
  config = function()
    require('scope').setup()
    require('telescope').load_extension('scope')
  end,
}
