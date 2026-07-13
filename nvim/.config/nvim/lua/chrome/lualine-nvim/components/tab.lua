--- @class chrome.lualine.components.tab
local M = {}

-- Ordered detectors that override the default `tab` prefix for special,
-- plugin-created tab pages. First match wins.
local detectors = {
  function(tabpage)
    -- codediff is lazy (cmd = 'CodeDiff'); requiring its module before it loads
    -- would force-load the whole plugin from a statusline redraw. When it isn't
    -- loaded there are no sessions, so bail without touching it.
    local package_utils = require('utils.package')
    if not package_utils.is_loaded('codediff.nvim') then
      return
    end

    local lifecycle = require('codediff.ui.lifecycle')
    if lifecycle.get_session(tabpage) then
      return 'codediff'
    end
  end,
}

--- @return string label e.g. "tab-2" or "codediff-2"
function M.get()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local prefix = 'tab'
  for _, detect in ipairs(detectors) do
    local result = detect(tabpage)
    if result then
      prefix = result
      break
    end
  end

  return prefix .. '-' .. vim.fn.tabpagenr()
end

--- @return boolean shown True when more than one tab page is open
function M.cond()
  return vim.fn.tabpagenr('$') > 1
end

M.icon = Conf.icons.misc.TAB

return M
