--- @class utils.ui
local M = {}

M.color = require('utils.ui.color')
M.layout = require('utils.ui.layout')
M.mode = require('utils.ui.mode')
-- Deferred: nothing reads these before a plugin loads
--- @type utils.ui.pill
M.pill = Defer.on_index('utils.ui.pill')
--- @type utils.ui.cursorline
M.cursorline = Defer.on_index('utils.ui.cursorline')
M.statusline = require('utils.ui.integrations.lualine-nvim')
M.which_key = require('utils.ui.integrations.which-key-nvim')
M.catppuccin = require('utils.ui.integrations.catppuccin-nvim')

return M
