-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.clipboard = "" -- turn off clipboard syncing

opt.pumblend = 0 -- fully opaque popupmenu
opt.pumheight = 15 -- Maximum number of entries in a popup

opt.spell = true -- keep it true to use cmp-spell, but hide the undercurl (see config.post.highlightgroups)
opt.spelloptions = ""
opt.list = false
-- opt.spelloptions:append("camel")
-- opt.winbar = "%=%m %f" -- basically a breadcrumb
