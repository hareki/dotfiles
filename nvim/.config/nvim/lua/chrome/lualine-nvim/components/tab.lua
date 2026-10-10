--- @class chrome.lualine.components.tab
local M = {}

--- @return string label e.g. "tab-2" or "codediff-2"
function M.get()
  local codediff_utils = require('features.git.codediff-nvim.utils')
  local prefix = codediff_utils.is_codediff_tab(vim.api.nvim_get_current_tabpage()) and 'codediff'
    or 'tab'

  return prefix .. '-' .. vim.fn.tabpagenr()
end

--- @return boolean shown True when more than one tab page is open
function M.cond()
  return vim.fn.tabpagenr('$') > 1
end

M.icon = Conf.icons.misc.TAB

return M
