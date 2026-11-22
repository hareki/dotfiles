--- @module 'features.navigation.vim-tmux-navigator.utils'
local navigator = Defer.on_exported_call('features.navigation.vim-tmux-navigator.utils')

return {
  'christoomey/vim-tmux-navigator',
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
    vim.g.tmux_navigator_preserve_zoom = 1
  end,
  keys = {
    {
      '<A-m>',
      function()
        navigator.navigate('left')
      end,
      mode = { 'n', 't' },
      desc = 'Go to Left Window',
    },
    {
      '<A-n>',
      function()
        navigator.navigate('down')
      end,
      mode = { 'n', 't' },
      desc = 'Go to Lower Window',
    },
    {
      '<A-e>',
      function()
        navigator.navigate('up')
      end,
      mode = { 'n', 't' },
      desc = 'Go to Upper Window',
    },
    {
      '<A-i>',
      function()
        navigator.navigate('right')
      end,
      mode = { 'n', 't' },
      desc = 'Go to Right Window',
    },
  },
}
