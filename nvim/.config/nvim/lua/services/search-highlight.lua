--- @class services.search-highlight
local M = {}

--- Clear search highlight and restore Snacks word highlights
--- The nvim-hlslens lens handler disables Snacks.words while search highlights are visible
--- (see `nvim-hlslens/utils.lua`'s `search_text_handler`), so a plain :nohlsearch would leave them off.
--- @return nil
function M.clear_search_highlight()
  vim.cmd.nohlsearch()
  Snacks.words.enable()
  Snacks.words.update()
end

return M
