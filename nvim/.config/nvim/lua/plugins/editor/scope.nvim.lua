return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
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
  config = true,
}
