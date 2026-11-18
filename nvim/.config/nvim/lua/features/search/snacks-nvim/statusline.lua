local tabs = require('features.search.snacks-nvim.sources.tabs')

--- The statusline's tab piece, placed by chrome/lualine-nvim/init.lua
--- @class features.search.snacks-nvim.statusline
local M = {}

--- @return string label e.g. "tab-2" or "codediff-2"
function M.get()
  return tabs.label(vim.api.nvim_get_current_tabpage())
end

--- @return boolean
function M.cond()
  return vim.fn.tabpagenr('$') > 1
end

M.icon = Conf.icons.misc.TAB
M.color = Conf.icons.colors.TAB

return M
