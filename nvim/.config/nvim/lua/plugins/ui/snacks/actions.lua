---@class plugins.ui.snacks.actions
local M = {}

---Create a scroll action that moves the list by half a page
---@param direction 'up' | 'down' The scroll direction
---@return fun(picker: snacks.Picker): nil action The scroll action function
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

---Toggle focus between the picker input and preview window
---@param picker snacks.Picker The picker instance
---@return nil
function M.toggle_preview_focus(picker)
  local input_win = picker.layout.opts.wins.input.win
  local preview_win = picker.layout.opts.wins.preview.win
  local current_win = vim.api.nvim_get_current_win()
  local common = require('utils.common')
  local reticle_utils = require('plugins.editor.reticle.utils')

  if current_win == preview_win then
    common.focus_win(input_win)
    reticle_utils.set_cursorline(false, preview_win)
    return
  end

  if common.focus_win(preview_win) then
    reticle_utils.set_cursorline(true, preview_win)
  end
end

---Select the current item in the picker list
---@param picker snacks.Picker The picker instance
---@return nil
function M.select(picker)
  picker.list:select()
end

---Send picker results to Trouble for persistent viewing
---Handles todo_comments source specially by opening Trouble's todo view.
---@param picker snacks.Picker The picker instance
---@return nil
function M.snacks_to_trouble(picker)
  if picker.opts.source == 'todo_comments' then
    local todo_args = { 'todo', 'toggle' }

    if picker.opts.keywords and #picker.opts.keywords > 0 then
      local tags = table.concat(picker.opts.keywords, ',')
      vim.list_extend(todo_args, { 'filter', '=', '{tag = {' .. tags .. '}}' })
    end

    picker:close()
    vim.cmd({ cmd = 'Trouble', args = todo_args })
  else
    local trouble_sources = require('trouble.sources.snacks')
    trouble_sources.open(picker)
  end
end

return M
