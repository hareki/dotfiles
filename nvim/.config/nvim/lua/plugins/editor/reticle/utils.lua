-- We need special treatment for telescope.nvim and reticle.nvim interaction
-- Since most of telescope/snacks pickers will do noautocmd when switching window

---@class plugins.editor.reticle.utils
local M = {}

M.always_highlight_number = true

function M.set_cursorline(enable, win)
  if M.always_highlight_number then
    vim.wo[win].cursorlineopt = enable and 'both' or 'number'
    vim.wo[win].cursorline = true
  else
    vim.wo[win].cursorline = enable
  end
end

return M
