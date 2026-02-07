-- Use Neovim's experimental Lua module loader that does byte-caching of Lua modules
-- Taken from https://github.com/mrjones2014/dotfiles/blob/master/nvim/init.lua#L2
vim.loader.enable(true)

require('config.globals')
require('config.options')
require('config.autocmds')
require('config.usercmds')
require('config.keymaps')
require('config.lazy')
