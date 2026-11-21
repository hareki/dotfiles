--- @module 'features.navigation.window-navigation.utils'
local navigator = Defer.on_exported_call('features.navigation.window-navigation.utils')

-- Move between windows, and on to the next Rex pane from a window at the edge. Rex sends these
-- keys for cmd+m/n/e/i while nvim runs in the pane (rex/.config/rex/features/pane-navigation.lua)
return {
  'window-navigation',
  virtual = true,
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
