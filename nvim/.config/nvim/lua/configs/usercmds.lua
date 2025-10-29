vim.api.nvim_create_user_command('TabRename', function(command_opts)
  vim.t.tab_name = command_opts.args
  require('lualine').refresh({ place = { 'statusline' } })
end, { nargs = 1 })
