-- We need special treatment for telescope.nvim and reticle.nvim interaction
-- Since most of telescope pickers will do noautocmd when switching window
local M = {}

M.always_highlight_number = true

function M.set_cursorline(enable, win)
  if M.always_highlight_number then
    vim.api.nvim_set_option_value('cursorlineopt', enable and 'both' or 'number', { win = win })
    vim.api.nvim_set_option_value('cursorline', true, { win = win })
  else
    vim.api.nvim_set_option_value('cursorline', enable, { win = win })
  end
end

return M
