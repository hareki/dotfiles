--- @class chrome.lualine.components.diff
local M = {}

M.symbols = {
  added = Conf.icons.git.ADDED,
  modified = Conf.icons.git.MODIFIED,
  removed = Conf.icons.git.REMOVED,
}

function M.source()
  local gitsigns = vim.b.gitsigns_status_dict

  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
end

return M
