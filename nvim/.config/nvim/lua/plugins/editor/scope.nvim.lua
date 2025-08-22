return {
  'tiagovla/scope.nvim',
  event = 'VeryLazy',
  config = function()
    require('scope').setup()
    require('telescope').load_extension('scope')
  end,
}
