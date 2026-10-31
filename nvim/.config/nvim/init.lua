-- Startup code runs once, so tracing it costs more than it saves
jit.off()
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('config.autocmds.boot-jit', { clear = true }),
  once = true,
  -- Not `callback = jit.on`, which rejects the autocmd's args table
  callback = function()
    jit.on()
  end,
})

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
    UI.cursorline.follow_focus()
    -- Kept off the startup path, see disabled_plugins in config/lazy/init.lua
    vim.cmd.packadd('matchit')
  end,
})

require('config.lazy')
