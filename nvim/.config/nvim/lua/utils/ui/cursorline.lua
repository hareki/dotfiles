--- @class utils.ui.cursorline
local M = {}

M.ALWAYS_HIGHLIGHT_NUMBER = true

--- Set cursorline state for a window
--- When ALWAYS_HIGHLIGHT_NUMBER is true, shows line numbers even when cursorline is disabled.
--- @param enable boolean Whether to enable full cursorline
--- @param win integer The window handle
--- @return nil
function M.set_cursorline(enable, win)
  if M.ALWAYS_HIGHLIGHT_NUMBER then
    vim.wo[win].cursorlineopt = enable and 'both' or 'number'
    vim.wo[win].cursorline = true
  else
    vim.wo[win].cursorline = enable
  end
end

return M
