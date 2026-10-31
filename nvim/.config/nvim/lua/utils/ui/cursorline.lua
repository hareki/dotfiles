--- @class utils.ui.cursorline
local M = {}

--- Show the full cursorline, or only the line number. Sets only what differs, since a same-value
--- set of these options still redraws the whole window
--- @param enable boolean Whether to enable full cursorline
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

--- @return nil
local function focus_cursorline()
  local win = vim.api.nvim_get_current_win()
  M.set_cursorline(not vim.wo[win].diff, win)
end

--- Keep the full cursorline on the focused window only, diff windows staying number-only
--- @return nil
function M.follow_focus()
  local group = vim.api.nvim_create_augroup('utils.ui.cursorline.follow-focus', { clear = true })

  vim.api.nvim_create_autocmd('WinEnter', { group = group, callback = focus_cursorline })
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
      vim.schedule(focus_cursorline)
    end,
  })

  -- Windows that predate the autocmds: `nvim -O`, restored splits
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.set_cursorline(false, win)
  end
  focus_cursorline()
end

return M
