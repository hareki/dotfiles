--- @class core.snacks.actions
local M = {}

local state = require('core.snacks-nvim.utils.state')

--- Wrap default toggle_preview to persist state for managed pickers
--- @module 'snacks'
--- @param picker snacks.Picker
function M.toggle_preview(picker)
  picker:toggle('preview')

  local source = picker.opts.source
  if source and state.managed(source) then
    local current = state.get(source, 'preview')
    state.set(source, 'preview', not current)
  end
end

--- Move the list cursor by half a page
--- @param picker snacks.Picker
--- @param direction 1 | -1 Down or up, flipped by the list itself for reversed layouts
local function move_half_page(picker, direction)
  -- state.height follows window resizes, unlike the state.scroll snacks samples once on show
  local half = math.max(1, math.floor(picker.list.state.height / 2))
  picker.list:move(direction * half)
end

--- @param picker snacks.Picker
function M.list_half_page_down(picker)
  move_half_page(picker, 1)
end

--- @param picker snacks.Picker
function M.list_half_page_up(picker)
  move_half_page(picker, -1)
end

--- Toggle focus between the picker input and preview window
--- @param picker snacks.Picker The picker instance
--- @return nil
function M.toggle_preview_focus(picker)
  local input_win = picker.layout.opts.wins.input.win
  local preview_win = picker.layout.opts.wins.preview.win
  local current_win = vim.api.nvim_get_current_win()
  local common = require('utils.common')

  -- No-op for pickers configured with `preview = false` (e.g. keymaps),
  -- where <Tab> is still bound globally but there is no window to focus
  if preview_win == nil then
    return
  end

  if current_win == preview_win then
    common.focus_win(input_win)
    UI.cursorline.set_cursorline(false, preview_win)
    return
  end

  if common.focus_win(preview_win) then
    UI.cursorline.set_cursorline(true, preview_win)
  end
end

--- Send picker results to Trouble for persistent viewing
--- @param picker snacks.Picker The picker instance
--- @return nil
function M.snacks_to_trouble(picker)
  local trouble_sources = require('trouble.sources.snacks')
  trouble_sources.open(picker)
end

--- The todo_comments source's snacks_to_trouble: opens Trouble's own todo view,
--- filtered to the picker's keywords
--- @param picker snacks.Picker The picker instance
--- @return nil
function M.todo_to_trouble(picker)
  local todo_args = { 'todo', 'toggle' }
  local keywords = picker
    --- @module "todo-comments"
    .opts --[[@as snacks.picker.todo.Config]]
    .keywords

  if keywords and #keywords > 0 then
    local tags = table.concat(keywords, ',')
    vim.list_extend(todo_args, { 'filter', '=', '{tag = {' .. tags .. '}}' })
  end

  picker:close()
  vim.cmd.Trouble({ args = todo_args })
end

return M
