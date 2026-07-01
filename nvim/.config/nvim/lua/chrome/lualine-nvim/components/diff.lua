--- @class chrome.lualine.components.diff
local M = {}

M.symbols = {
  added = Conf.Icons.git.added,
  modified = Conf.Icons.git.modified,
  removed = Conf.Icons.git.removed,
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
