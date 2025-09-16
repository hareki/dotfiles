local M = {}
---@param direction 'up' | 'down'
function M.scroll_half_page(direction)
  return function(picker)
    local list_win = picker.layout.opts.wins.list.win
    local h = vim.api.nvim_win_get_height(list_win)
    local row = vim.api.nvim_win_get_cursor(list_win)[1]
    local target_row = row + (math.max(1, math.floor(h / 2))) * (direction == 'up' and -1 or 1)
    local idx = picker.list:row2idx(target_row)
    picker.list:_move(idx, true, true)
  end
end

function M.toggle_preview_focus(picker)
  vim.notify('Toggle')
  local input_win = picker.layout.opts.wins.input.win
  local preview_win = picker.layout.opts.wins.preview.win
  local current_win = vim.api.nvim_get_current_win()

  if current_win == input_win then
    vim.api.nvim_set_current_win(preview_win)
  else
    vim.api.nvim_set_current_win(input_win)
  end
end

function M.select(picker)
  picker.list:select()
end

function M.snacks_to_trouble(picker)
  require('trouble.sources.snacks').open(picker)
end

return M
