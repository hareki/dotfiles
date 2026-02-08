return {
  'tummetott/reticle.nvim',
  event = 'VeryLazy',
  opts = function()
    local utils = require('services.cursorline')

    return {
      disable_in_insert = false,
      disable_in_diff = true,
      always_highlight_number = utils.always_highlight_number,
      ignore = {
        cursorline = {
          'toggleterm',
          'TelescopePrompt',
        },
      },
    }
  end,
}
