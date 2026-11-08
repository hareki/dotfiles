--- @class features.search.snacks-nvim.actions
local M = {}

--- Whether the preview is shown, for the sources that keep it across openings (their
--- keymaps open them with it); add a source here to have toggle_preview remember it
--- @type table<string, boolean>
M.preview_shown = { files = true }

--- Wrap default toggle_preview to remember the choice for the sources in M.preview_shown
--- @module 'snacks'
--- @param picker snacks.Picker
function M.toggle_preview(picker)
  picker:toggle('preview')

  local source = picker.opts.source
  if source and M.preview_shown[source] ~= nil then
    M.preview_shown[source] = not M.preview_shown[source]
  end
end

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
--- @param picker snacks.Picker
--- @return nil
function M.toggle_preview_focus(picker)
  local popup = require('utils.popup')
  local preview_win = picker.preview.win.win

  -- No-op for pickers with `preview = false` (e.g. keymaps), where <Tab> is still bound
  if not preview_win then
    return
  end

  if picker:current_win() == 'preview' then
    popup.focus_win(picker.input.win.win)
  else
    popup.focus_win(preview_win)
  end
end

--- Send picker results to Trouble for persistent viewing
--- @param picker snacks.Picker
--- @return nil
function M.snacks_to_trouble(picker)
  local trouble_sources = require('trouble.sources.snacks')
  trouble_sources.open(picker)
end

--- The todo_comments source's snacks_to_trouble: Trouble's todo view, filtered to its keywords
--- @param picker snacks.Picker
--- @return nil
function M.todo_to_trouble(picker)
  local keywords = picker
    --- @module "todo-comments"
    .opts --[[@as snacks.picker.todo.Config]]
    .keywords

  picker:close()
  local trouble = require('trouble')
  --- @diagnostic disable-next-line: missing-fields
  trouble.toggle({
    mode = 'todo',
    filter = keywords and { tag = keywords },
  })
end

return M
