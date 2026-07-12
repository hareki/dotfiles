--- @class utils.ui
local M = {}

M.pill = require('utils.ui.pill')
M.color = require('utils.ui.color')
M.layout = require('utils.ui.layout')
M.cursorline = require('utils.ui.cursorline')
M.statusline = require('utils.ui.integrations.lualine-nvim')
M.which_key = require('utils.ui.integrations.which-key-nvim')
M.catppuccin = require('utils.ui.integrations.catppuccin-nvim')

return M
