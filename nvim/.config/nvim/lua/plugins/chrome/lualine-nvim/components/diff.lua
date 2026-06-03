---@class plugins.chrome.lualine.components.diff
local M = {}

M.symbols = {
  added = Icons.git.added,
  modified = Icons.git.modified,
  removed = Icons.git.removed,
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
