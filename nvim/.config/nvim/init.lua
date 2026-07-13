local function lazy(fn)
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('config.init.lazy', { clear = true }),
    pattern = 'VeryLazy',
    once = true,
    callback = fn,
  })
end

vim.loader.enable(true)

require('config.globals')
require('config.options')
require('config.autocmds')

lazy(function()
  require('config.usercmds')
  require('config.keymaps')
end)

require('config.lazy')
