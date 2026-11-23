--- @class features.search.snacks-nvim.actions
local M = {}

--- @class features.search.snacks-nvim.actions.State
--- @field preview_hidden table<string, boolean> Whether toggle_preview last hid a source's preview

--- @type features.search.snacks-nvim.actions.State
local state = { preview_hidden = {} }

--- A source's `config` hook, which makes its preview toggle carry across openings: open with the
--- preview shown or hidden as toggle_preview last left it, whoever opens the picker. snacks runs it
--- more than once per open, so it only reads the choice
--- @param opts snacks.picker.Config The source's merged config
function M.remembered_preview(opts)
  local layout = opts.layout --[[@as snacks.picker.layout.Config]]
  layout.hidden = state.preview_hidden[opts.source] and { 'preview' } or {}
end

--- Wrap default toggle_preview to record the choice, which only a source with the hook reads
--- @module 'snacks'
--- @param picker snacks.Picker
function M.toggle_preview(picker)
  picker:toggle('preview')

  local source = picker.opts.source
  if source then
    state.preview_hidden[source] = picker.layout:is_hidden('preview')
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

  -- No-op while the preview is hidden (as the keymaps picker opens), where <Tab> is still bound
  if not preview_win then
    return
  end

  if picker:current_win() == 'preview' then
    popup.focus_win(picker.input.win.win)
  else
    popup.focus_win(preview_win)
  end
end

return M
