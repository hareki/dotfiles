return {
  'tummetott/reticle.nvim',
  event = 'VeryLazy',
  opts = {
    disable_in_insert = false,
    disable_in_diff = true,
    always_highlight_number = require('plugins.editor.reticle.utils').always_highlight_number,
    ignore = {
      cursorline = {
        'toggleterm',
        'TelescopePrompt',
        'AvantePromptInput',
      },
    },
  },
}
