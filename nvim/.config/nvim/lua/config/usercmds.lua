vim.api.nvim_create_user_command('HlAtCursor', function()
  local hl_at_cursor = require('utils.hl-at-cursor')
  hl_at_cursor.show()
end, { desc = 'Show Highlight Groups Under Cursor' })
