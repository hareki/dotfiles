--- @class utils.ui.cursorline
local M = {}

--- Full cursorline or only the number, setting only what differs: a same-value set still redraws.
--- A no-op on the window in Terminal mode: Neovim restores both options as the mode leaves it
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

--- Give the current window the focused cursorline: the full line, or only the number in a diff
--- @return nil
function M.focus()
  local win = vim.api.nvim_get_current_win()
  M.set_cursorline(not vim.wo[win].diff, win)
end

--- Full cursorline on the focused window only; diffs show only the number, Terminal mode none
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

      -- Terminal mode restores the window's values after the key that left it: unfocus after that.
      -- A callback's switch runs this ahead of the restore instead, which TermLeave makes up for
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
      -- Neovim has just restored the mode window's values (a float's `style = 'minimal'`, the full
      -- line on a terminal focus has left since), and skipped any window entered during the mode
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
