-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- disable LazyVim autoformat as it's synchronous, it feels laggy
vim.g.autoformat = false
vim.b.autoformat = false

local opt = vim.opt

opt.clipboard = "" -- turn off clipboard syncing

opt.pumblend = 0 -- fully opaque popupmenu
opt.pumheight = 15 -- Maximum number of entries in a popup

opt.list = false -- hide whitespace characters

opt.spell = true -- keep it true to use cmp-spell, but hide the undercurl (see extras.custom_highlights)
-- opt.spelloptions:append("camel")
-- opt.spelloptions = ""

-- opt.winbar = "%=%m %f" -- basically a breadcrumb

-- vim.g.git_worktree = {
-- change_directory_command = "vim.api.nvim_set_current_dir",
-- }
