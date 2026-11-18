--- The statusline's diff counts, placed by chrome/lualine-nvim/init.lua
--- @class features.git.gitsigns-nvim.statusline
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
