--- Search highlighting, which Snacks word references give way to while it shows (the words filter
--- in core/lsp/snacks-nvim.lua)
--- @class utils.ui.search
local M = {}

--- @return boolean
function M.is_active()
  -- v:hlsearch alone reads 1 before any search when no shada was loaded
  return vim.v.hlsearch == 1 and vim.fn.getreg('/') ~= ''
end

--- Clear search highlight and bring Snacks word highlights back now, not on the next cursor move
--- @return nil
function M.clear()
  -- :nohlsearch redraws every window even with highlighting off, and <Esc> calls this per press
  if vim.v.hlsearch == 0 then
    return
  end

  -- With no search highlighted nothing was hidden, so update() would only re-request references
  local was_active = M.is_active()
  vim.cmd.nohlsearch()
  if was_active then
    local snacks_words = require('snacks.words')
    snacks_words.update()
  end
end

return M
