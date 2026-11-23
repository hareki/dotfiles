-- features.search.snacks-nvim.actions: the files picker's remembered preview, which every files
-- picker opens with whoever opens it, and the keymaps picker, which opens without a preview

local t = require('tests.lib.helpers')
local actions = require('features.search.snacks-nvim.actions')
local live_preview = require('features.preview.live-preview-nvim.utils')

-- Files for the files pickers to list: a picker that finds nothing closes before it shows
vim.fn.writefile({ '# Notes' }, 'notes.md')
vim.fn.writefile({ 'return {}' }, 'init.lua')

--- The callback of the normal-mode map with this desc
--- @param desc string
--- @return function
local function callback_described(desc)
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.desc == desc then
      return t.ok(map.callback, string.format('%s maps no callback', desc))
    end
  end
  error(string.format('no normal-mode map is described as %s', desc))
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

--- Open a files picker with its keymap, hide its preview with toggle_preview and close it
local function hide_files_preview()
  local picker = t.open_picker(callback_described('Find Files'), 'files')
  t.eq(preview_visible(picker), true, 'the files picker shows its preview before the toggle')
  picker:action('toggle_preview')
  expect_preview(picker, false, 'toggle_preview to hide the preview')
  t.close_picker(picker)
end

--- When the test ends, show the files picker's preview again if the test left it hidden: the
--- choice outlives a picker, so the next test would open on it
local function show_preview_after()
  t.cleanup(function()
    local picker = t.open_picker(callback_described('Find Files'), 'files')
    if not preview_visible(picker) then
      picker:action('toggle_preview')
      expect_preview(picker, true, 'the preview to show again')
    end
  end)
end

t.test('<Tab> moves focus into a shown preview and back to the input', function()
  local picker = t.open_picker(callback_described('Find Files'), 'files')

  t.map_callback('i', '<Tab>', picker.input.win.buf)()
  t.eq(vim.api.nvim_get_current_win(), picker.preview.win.win, '<Tab> focuses the preview')
  actions.toggle_preview_focus(picker)
  t.eq(vim.api.nvim_get_current_win(), picker.input.win.win, 'toggling again focuses the input')
end)

t.test("toggle_preview's choice holds for the next files picker until toggled back", function()
  show_preview_after()
  local find_files = callback_described('Find Files')
  hide_files_preview()

  local picker = t.open_picker(find_files, 'files')
  t.eq(preview_visible(picker), false, 'the next files picker opens without it')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the preview again')
  t.close_picker(picker)

  picker = t.open_picker(find_files, 'files')
  t.eq(preview_visible(picker), true, 'the files picker after that shows it')
end)

t.test('a files picker opened with no layout, or resumed, follows the remembered choice', function()
  show_preview_after()
  hide_files_preview()

  local picker = t.open_picker(function()
    Snacks.picker.files()
  end, 'files')
  t.eq(preview_visible(picker), false, 'Snacks.picker.files() opens without the preview')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the preview in it')
  t.close_picker(picker)

  hide_files_preview()
  picker = t.open_picker(function()
    Snacks.picker.resume({ source = 'files' })
  end, 'files')
  t.eq(preview_visible(picker), false, 'the resumed files picker opens without it')
end)

t.test("live-preview's picker shares the files picker's remembered preview", function()
  show_preview_after()
  local find_files = callback_described('Find Files')
  hide_files_preview()

  local picker = t.open_picker(live_preview.pick, 'files')
  t.eq(picker.opts.title, 'Live Preview', "live-preview's picker is the one open")
  t.eq(preview_visible(picker), false, 'it opens without the preview the files picker hid')
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the preview in it')
  t.close_picker(picker)

  picker = t.open_picker(find_files, 'files')
  t.eq(preview_visible(picker), true, 'the files picker follows the toggle made in it')
end)

t.test('the keymaps picker opens without a preview, where <Tab> does nothing', function()
  show_preview_after()
  local picker = t.open_picker(callback_described('Find Keymaps'), 'keymaps')
  t.eq(preview_visible(picker), false, 'the keymaps picker shows no preview')
  t.eq(picker.resolved_layout.hidden, { 'preview' }, 'its layout hides the preview')

  local input_win = vim.api.nvim_get_current_win()
  t.eq(input_win, picker.input.win.win, 'the input has focus')
  t.map_callback('i', '<Tab>', picker.input.win.buf)()
  t.eq(vim.api.nvim_get_current_win(), input_win, '<Tab> leaves focus in the input')

  -- A source outside the remembered ones toggles for this opening only
  picker:action('toggle_preview')
  expect_preview(picker, true, 'toggle_preview to show the keymaps preview')
  t.close_picker(picker)

  picker = t.open_picker(callback_described('Find Keymaps'), 'keymaps')
  t.eq(preview_visible(picker), false, 'the next keymaps picker opens without it again')
  t.close_picker(picker)

  picker = t.open_picker(callback_described('Find Files'), 'files')
  t.eq(preview_visible(picker), true, "the files picker's memory is untouched")
end)
