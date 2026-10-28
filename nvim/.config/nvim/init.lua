vim.loader.enable(true)

require('config.globals')
require('config.options')
require('config.filetypes')
require('config.autocmds')

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('config.autocmds.deferred-boot', { clear = true }),
  pattern = 'VeryLazy',
  once = true,
  callback = function()
    require('config.usercmds')
    require('config.keymaps')
    -- Kept off the startup path, see disabled_plugins in config/lazy/init.lua
    vim.cmd.packadd('matchit')
  end,
})

require('config.lazy')
