-- features.search.snacks-nvim.actions: the files picker's remembered preview, which its keymap and
-- live-preview's picker open with, and the keymaps picker, which opens without a preview

local t = require('tests.lib.helpers')
local actions = require('features.search.snacks-nvim.actions')
local live_preview = require('features.preview.live-preview-nvim.utils')

-- Files for the files pickers to list: a picker that finds nothing closes before it shows
vim.fn.writefile({ '# Notes' }, 'notes.md')
vim.fn.writefile({ 'return {}' }, 'init.lua')

local SHOWN = { hidden = {} }
local HIDDEN = { hidden = { 'preview' } }

--- The callback of the normal-mode map with this desc
--- @param desc string
--- @return function
local function map_callback(desc)
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.desc == desc then
      return t.ok(map.callback, string.format('%s maps no callback', desc))
    end
  end
  error(string.format('no normal-mode map is described as %s', desc))
end

--- Close the picker and wait for the teardown snacks schedules
--- @param picker snacks.Picker
local function close_picker(picker)
  picker:close()
  t.wait_for(function()
    return picker.preview == nil
  end, 'the picker teardown')
end

--- Run `open` and wait for the picker of `source` it opens to list its items
--- @param open fun()
--- @param source string
--- @return snacks.Picker
local function open_picker(open, source)
  -- Opening a source that is already open closes it instead, so drop one a failed test left
  for _, stale in ipairs(Snacks.picker.get({ source = source })) do
    close_picker(stale)
  end

  open()
  local picker --- @type snacks.Picker?
  t.wait_for(function()
    picker = Snacks.picker.get({ source = source })[1]
    return picker ~= nil and picker.shown == true and #picker:items() > 0
  end, string.format('the %s picker to list its items', source))
  --- @cast picker snacks.Picker
  return picker
end

--- @param picker snacks.Picker
--- @return boolean
local function preview_visible(picker)
  return not picker.layout:is_hidden('preview') and picker.preview.win:valid()
end

--- @param picker snacks.Picker
--- @param visible boolean
--- @param msg string
local function expect_preview(picker, visible, msg)
  t.wait_for(function()
    return preview_visible(picker) == visible
  end, msg)
end

--- The callback of a buffer-local map in the picker's input window
--- @param picker snacks.Picker
--- @param mode string
--- @param lhs string
--- @return function
local function input_map(picker, mode, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(picker.input.win.buf, mode)) do
    if vim.fn.keytrans(map.lhsraw) == lhs then
      return t.ok(map.callback, string.format('%s maps no callback', lhs))
    end
  end
  error(string.format('the input window maps no %s in mode %s', lhs, mode))
end

t.test('<Tab> moves focus into a shown preview and back to the input', function()
  local picker = open_picker(map_callback('Find Files'), 'files')

  input_map(picker, 'i', '<Tab>')()
  t.eq(vim.api.nvim_get_current_win(), picker.preview.win.win, '<Tab> focuses the preview')
  actions.toggle_preview_focus(picker)
  t.eq(vim.api.nvim_get_current_win(), picker.input.win.win, 'toggling again focuses the input')
  close_picker(picker)
end)

t.test("toggle_preview's choice holds for the next files picker until toggled back", function()
  local find_files = map_callback('Find Files')
  t.eq(actions.preview_layout('files'), SHOWN, 'the layout before any toggle')

  local picker = open_picker(find_files, 'files')
  t.eq(preview_visible(picker), true, 'the first files picker shows its preview')
  picker:action('toggle_preview')
  expect_preview(picker, false, 'toggle_preview to hide the preview')
  t.eq(actions.preview_layout('files'), HIDDEN, 'the layout after hiding it')
  close_picker(picker)

  picker = open_picker(find_files, 'files')
  t.eq(preview_visible(picker), false, 'the next files picker opens without it')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the preview again')
  close_picker(picker)

  picker = open_picker(find_files, 'files')
  t.eq(preview_visible(picker), true, 'the files picker after that shows it')
  close_picker(picker)
  t.eq(actions.preview_layout('files'), SHOWN, 'the layout after showing it again')
end)

t.test("live-preview's picker shares the files picker's remembered preview", function()
  local find_files = map_callback('Find Files')
  local picker = open_picker(find_files, 'files')
  picker:action('toggle_preview')
  expect_preview(picker, false, 'toggle_preview to hide the preview')
  close_picker(picker)

  picker = open_picker(live_preview.pick, 'files')
  t.eq(picker.opts.title, 'Live Preview', "live-preview's picker is the one open")
  t.eq(preview_visible(picker), false, 'it opens without the preview the files picker hid')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the preview in it')
  close_picker(picker)

  picker = open_picker(find_files, 'files')
  t.eq(preview_visible(picker), true, 'the files picker follows the toggle made in it')
  close_picker(picker)
end)

t.test('the keymaps picker opens without a preview, where <Tab> does nothing', function()
  local picker = open_picker(map_callback('Find Keymaps'), 'keymaps')
  t.eq(preview_visible(picker), false, 'the keymaps picker shows no preview')
  t.eq(picker.resolved_layout.hidden, { 'preview' }, 'its layout hides the preview')

  local input_win = vim.api.nvim_get_current_win()
  t.eq(input_win, picker.input.win.win, 'the input has focus')
  input_map(picker, 'i', '<Tab>')()
  t.eq(vim.api.nvim_get_current_win(), input_win, '<Tab> leaves focus in the input')

  -- A source outside the remembered ones toggles for this opening only
  local files_layout = actions.preview_layout('files')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the keymaps preview')
  t.eq(actions.preview_layout('files'), files_layout, "the files picker's memory is untouched")
  close_picker(picker)

  picker = open_picker(map_callback('Find Keymaps'), 'keymaps')
  t.eq(preview_visible(picker), false, 'the next keymaps picker opens without it again')
  close_picker(picker)
end)
