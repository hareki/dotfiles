vim.api.nvim_create_user_command('HlAtCursor', function()
  require('utils.hl-at-cursor').show()
end, { desc = 'Show Highlight Groups Under Cursor' })

if require('plugins.ui.lualine.utils').have_status_line() then
  vim.api.nvim_create_user_command('TabRename', function(opts)
    vim.t.tab_name = opts.args
    require('lualine').refresh({ place = { 'statusline' } })
  end, { nargs = 1 })
end
