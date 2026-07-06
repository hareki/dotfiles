--- @class chrome.lualine.components.diff
local M = {}

M.symbols = {
  added = Conf.Icons.git.ADDED,
  modified = Conf.Icons.git.MODIFIED,
  removed = Conf.Icons.git.REMOVED,
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
