local lazy_require = require('utils.lazy-require')

--- @class utils.ui
local M = {}

M.color = require('utils.ui.color')
M.layout = require('utils.ui.layout')
M.mode = require('utils.ui.mode')
-- Deferred: nothing reads these before a plugin loads
--- @module 'utils.ui.pill'
M.pill = lazy_require.on_index('utils.ui.pill')
--- @module 'utils.ui.cursorline'
M.cursorline = lazy_require.on_index('utils.ui.cursorline')
--- @module 'utils.ui.search'
M.search = lazy_require.on_index('utils.ui.search')
--- @module 'utils.ui.statusline'
M.statusline = lazy_require.on_index('utils.ui.statusline')
M.integration = require('utils.ui.integration')
M.which_key = require('utils.ui.which-key-nvim')
M.catppuccin = require('utils.ui.catppuccin-nvim')

return M
