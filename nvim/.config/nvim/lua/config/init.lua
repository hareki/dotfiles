-- Cross-references between config modules must use require directly, not the
-- Conf global, which is only assigned after this module finishes loading
--- @class config
local M = {}

M.filetypes = require('config.filetypes')
M.icons = require('config.icons')
M.priority = require('config.priority')
M.picker = require('config.picker')
M.size = require('config.size')
M.cmp = require('config.completion')

return M
