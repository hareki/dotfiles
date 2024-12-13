-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/hareki/LazyVim/blob/main/lua/lazyvim/config/options.lua

local g = vim.g
local b = vim.b
local opt = vim.opt

-- disable LazyVim autoformat as it's synchronous, it feels laggy
g.autoformat = false
g.lazyvim_eslint_auto_format = false
g.snacks_animate = false

b.autoformat = false
b.lazyvim_eslint_auto_format = false

opt.clipboard = "" -- turn off clipboard syncing
opt.scrolloff = 6 -- Lines of context
opt.smoothscroll = false
opt.tabline = "%!v:lua.Util.get_rendered_tabline()"

opt.pumblend = 0 -- fully opaque popupmenu
opt.pumheight = 15 -- Maximum number of entries in a popup

opt.list = false -- hide whitespace characters

opt.spell = true -- keep it true to use cmp-spell, but hide the undercurl (see extras.custom_highlights)
-- opt.spelloptions:append("camel")
-- opt.spelloptions = ""
