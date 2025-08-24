-- Use Neovim's experimental Lua module loader that does byte-caching of Lua modules
-- Taken from https://github.com/mrjones2014/dotfiles/blob/master/nvim/init.lua#L2
vim.loader.enable(true)

require('configs.globals')
require('configs.options')
require('configs.autocmds')
require('configs.usercmds')
require('configs.keymaps')
require('configs.lazy')
