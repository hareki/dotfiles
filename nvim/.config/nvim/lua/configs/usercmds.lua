vim.api.nvim_create_user_command('HlAtCursor', function()
  local hl_at_cursor = require('utils.hl-at-cursor')
  hl_at_cursor.show()
end, { desc = 'Show Highlight Groups Under Cursor' })

local lualine_utils = require('plugins.ui.lualine.utils')
if lualine_utils.have_status_line() then
  vim.api.nvim_create_user_command('TabRename', function(opts)
    vim.t.tab_name = opts.args
    local lualine = require('lualine')
    lualine.refresh({ place = { 'statusline' } })
  end, { nargs = 1 })
end
