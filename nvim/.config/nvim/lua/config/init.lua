-- Config modules must require each other directly: Conf is assigned only after this module loads
--- @class config
local M = {}

M.filetypes = require('config.filetypes.groups')
M.icons = require('config.icons')
M.priority = require('config.priority')
M.picker = require('config.picker')
M.size = require('config.size')
-- Deferred: only lazy-loaded plugins' opts read it
--- @type config.completion
M.cmp = Defer.on_index('config.completion')

return M
