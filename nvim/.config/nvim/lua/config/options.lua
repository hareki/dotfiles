-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- disable LazyVim autoformat as it's synchronous, it feels laggy
vim.g.autoformat = false
vim.b.autoformat = false

vim.g.lazyvim_eslint_auto_format = false
vim.b.lazyvim_eslint_auto_format = false

-- vim.g.git_worktree = {
-- change_directory_command = "vim.api.nvim_set_current_dir",
-- }

local opt = vim.opt

opt.clipboard = "" -- turn off clipboard syncing
opt.scrolloff = 6 -- Lines of context
opt.smoothscroll = false

opt.pumblend = 0 -- fully opaque popupmenu
opt.pumheight = 15 -- Maximum number of entries in a popup

opt.list = false -- hide whitespace characters

opt.spell = true -- keep it true to use cmp-spell, but hide the undercurl (see extras.custom_highlights)
-- opt.spelloptions:append("camel")
-- opt.spelloptions = ""
