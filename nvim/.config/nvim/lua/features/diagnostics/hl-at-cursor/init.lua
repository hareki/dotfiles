-- A popup of the highlight groups, captures, extmarks and matches at the cursor
return {
  'hl-at-cursor',
  virtual = true,
  cmd = 'HlAtCursor',
  keys = {
    { '<leader>?h', '<cmd>HlAtCursor<cr>', desc = 'Highlight Groups at Cursor' },
  },

  config = function()
    vim.api.nvim_create_user_command('HlAtCursor', function()
      local utils = require('features.diagnostics.hl-at-cursor.utils')
      utils.show()
    end, { desc = 'Show Highlight Groups at Cursor' })
  end,
}
