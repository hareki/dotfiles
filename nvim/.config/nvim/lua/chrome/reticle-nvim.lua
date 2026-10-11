return {
  'tummetott/reticle.nvim',
  event = 'VeryLazy',
  opts = function()
    return {
      disable_in_insert = false,
      always_highlight_number = UI.cursorline.ALWAYS_HIGHLIGHT_NUMBER,
      ignore = {
        -- Empty, not absent: it replaces the default list (NvimTree, Trouble, ...), whose
        -- windows keep reticle's cursorline handling
        cursorline = {},
      },
    }
  end,
}
