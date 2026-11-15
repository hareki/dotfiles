--- @class utils.ui.cursorline
local M = {}

--- Show the full cursorline, or only the line number. Sets only what differs, since a same-value
--- set of these options still redraws the whole window. A no-op on the window in Terminal mode,
--- where Neovim takes both options over (the cursor follows the program's output) and, once the
--- mode leaves the window, puts back what it had when the mode reached it, over whatever was set
--- in between
--- @param enable boolean
--- @param win integer
--- @return nil
function M.set_cursorline(enable, win)
  if vim.api.nvim_get_mode().mode == 't' and win == vim.api.nvim_get_current_win() then
    return
  end

  local wo = vim.wo[win]
  local opt = enable and 'both' or 'number'

  if wo.cursorlineopt ~= opt then
    wo.cursorlineopt = opt
  end
  if not wo.cursorline then
    wo.cursorline = true
  end
end

--- Give the current window the focused window's cursorline: the full line, or only the number in a
--- diff window
--- @return nil
function M.focus()
  local win = vim.api.nvim_get_current_win()
  M.set_cursorline(not vim.wo[win].diff, win)
end

--- Keep the full cursorline on the focused window only, diff windows staying number-only and
--- terminals showing none in Terminal mode
--- @return nil
function M.follow_focus()
  local group = vim.api.nvim_create_augroup('utils.ui.cursorline.follow-focus', { clear = true })

  vim.api.nvim_create_autocmd('WinEnter', { group = group, callback = M.focus })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_get_mode().mode ~= 't' then
        M.set_cursorline(false, win)
        return
      end

      -- Terminal mode lets the window go once the key that left it is done, putting back what it
      -- had when the mode reached it (the full line, if focused then): unfocused after that. A
      -- callback's switch runs this ahead of that instead, which TermLeave makes up for
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) and win ~= vim.api.nvim_get_current_win() then
          M.set_cursorline(false, win)
        end
      end)
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
      -- Neovim has just put back what the mode's window had when the mode reached it: a float's
      -- `style = 'minimal'`, or the full line on a terminal that focus has left since (as on one
      -- a callback switched away from mid-mode, ahead of WinLeave's fix). And a window entered
      -- during the mode was skipped
      local current = vim.api.nvim_get_current_win()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= current and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'terminal' then
          M.set_cursorline(false, win)
        end
      end
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
