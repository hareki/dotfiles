-- Special treatment for telescope.nvim and reticle.nvim interaction.
-- Most telescope/snacks pickers do noautocmd when switching windows.

---@class plugins.ui.reticle.utils
local M = {}

M.always_highlight_number = true

---Set cursorline state for a window
---When always_highlight_number is true, shows line numbers even when cursorline is disabled.
---@param enable boolean Whether to enable full cursorline
---@param win integer The window handle
---@return nil
function M.set_cursorline(enable, win)
  if M.always_highlight_number then
    vim.wo[win].cursorlineopt = enable and 'both' or 'number'
    vim.wo[win].cursorline = true
  else
    vim.wo[win].cursorline = enable
  end
end

return M
