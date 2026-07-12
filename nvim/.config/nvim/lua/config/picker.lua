-- Conf isn't assigned yet while config modules load; require directly
local icons = require('config.icons')

--- @class config.picker
local M = {}

M.PROMPT_PREFIX = ' ' .. icons.actions.SEARCH .. ' '
M.PREVIEW_TITLE = ''
M.TELESCOPE_PREVIEW_TITLE = false

return M
