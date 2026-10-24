--- @class chrome.lualine.components.tab
local M = {}

--- @param tabpage integer
--- @return string name e.g. "tab-2" or "codediff-2"
function M.name(tabpage)
  local codediff_utils = require('features.git.codediff-nvim.utils')
  local prefix = codediff_utils.is_codediff_tab(tabpage) and 'codediff' or 'tab'

  return prefix .. '-' .. vim.api.nvim_tabpage_get_number(tabpage)
end

--- @return string label e.g. "tab-2" or "codediff-2"
function M.get()
  return M.name(vim.api.nvim_get_current_tabpage())
end

--- @return boolean
function M.cond()
  return vim.fn.tabpagenr('$') > 1
end

M.icon = Conf.icons.misc.TAB
M.color = 'green' -- Catppuccin palette key, shared with the tabs picker's labels

return M
