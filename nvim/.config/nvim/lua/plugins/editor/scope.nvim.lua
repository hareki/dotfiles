return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  config = true,
  keys = function()
    return {
      {
        '<leader>fB',
        function()
          require('plugins.ui.snacks.pickers.scope')()
        end,
        desc = 'Find All Buffers',
      },
    }
  end,
}
