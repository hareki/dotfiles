vim.loader.enable(true)

-- A lone directory argument is the project: adopt it as the cwd before anything reads it
local first_arg = vim.fn.argv(0) --[[@as string]]
if vim.fn.argc() == 1 and vim.fn.isdirectory(first_arg) == 1 then
  -- Not :cd, which expands `#`, `%` and `$` in the name and would abort init.lua on them
  vim.api.nvim_set_current_dir(first_arg)
end

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
