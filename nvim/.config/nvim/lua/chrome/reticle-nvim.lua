return {
  'tummetott/reticle.nvim',
  event = 'VeryLazy',
  opts = function()
    return {
      disable_in_insert = false,
      always_highlight_number = UI.cursorline.ALWAYS_HIGHLIGHT_NUMBER,
      ignore = {
        cursorline = {
          'TelescopePrompt',
        },
      },
    }
  end,
}
