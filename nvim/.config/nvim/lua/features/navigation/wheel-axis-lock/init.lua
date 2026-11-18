-- Lock each trackpad swipe to one axis, as browsers do: terminals report every bit of drift
return {
  'wheel-axis-lock',
  virtual = true,
  event = 'VeryLazy',

  init = function()
    -- Ticks fire per cell, so hor:3 would match ver's on-screen speed; 2 pans deliberately slower
    vim.opt.mousescroll = 'ver:3,hor:2'
  end,

  config = function()
    local utils = require('features.navigation.wheel-axis-lock.utils')
    utils.map_wheel_keys()
  end,
}
