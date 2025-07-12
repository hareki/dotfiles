-- Use Neovim's experimental Lua module loader that does byte-caching of Lua modules
-- Taken from https://github.com/mrjones2014/dotfiles/blob/master/nvim/init.lua#L2
vim.loader.enable()

require('configs.global')
require('configs.options')
require('configs.autocmds')
require('configs.keymaps')
require('configs.core')
