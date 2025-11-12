return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>fB',
      function()
        require('plugins.ui.snacks.pickers.scope')()
      end,
      desc = 'Find All Buffers',
    },
  },
}
