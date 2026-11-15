--- @class utils.ui.cursorline
local M = {}

--- Show the full cursorline, or only the line number. Sets only what differs, since a same-value
--- set of these options still redraws the whole window
--- @param enable boolean
--- @param win integer
--- @return nil
function M.set_cursorline(enable, win)
  local wo = vim.wo[win]
  local opt = enable and 'both' or 'number'

  if wo.cursorlineopt ~= opt then
    wo.cursorlineopt = opt
  end
  if not wo.cursorline then
    wo.cursorline = true
  end
end

--- Give a window the focused window's cursorline: the full line, or only the number in a diff window.
--- A no-op in Terminal mode, where Neovim hides the line itself (the cursor follows the program's
--- output) and restores it once the mode ends
--- @param win? integer The current window by default
--- @return nil
function M.focus(win)
  if vim.api.nvim_get_mode().mode == 't' then
    return
  end

  win = win or vim.api.nvim_get_current_win()
  M.set_cursorline(not vim.wo[win].diff, win)
end

--- Keep the full cursorline on the focused window only, diff windows staying number-only and
--- terminals showing none in Terminal mode
--- @return nil
function M.follow_focus()
  local group = vim.api.nvim_create_augroup('utils.ui.cursorline.follow-focus', { clear = true })

  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      M.focus()
    end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = function()
      M.set_cursorline(false, vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function()
      -- Scheduled: a float's `style = 'minimal'` lands after its enter events, and a float opened
      -- without focus fires this while briefly the current window
      vim.schedule(M.focus)
    end,
  })
  vim.api.nvim_create_autocmd('TermLeave', {
    group = group,
    callback = function()
      -- Neovim restores what the window had when Terminal mode began, which may predate a float's
      -- `style = 'minimal'`, and a window entered from Terminal mode skipped focus()
      M.focus()
    end,
  })

  -- Windows that predate the autocmds: `nvim -O`, restored splits
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.set_cursorline(false, win)
  end
  M.focus()
end

return M
