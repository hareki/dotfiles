-- features.search.snacks-nvim.sources.tabs through Snacks.picker.tabs(), its keys and tab label

local t = require('tests.lib.helpers')
local tabs = require('features.search.snacks-nvim.sources.tabs')

--- @class tests.search-tabs.Fixture
--- @field tabs integer[] The tabpages, in order
--- @field file integer The second tab's buffer, editing a file
--- @field scratch integer The third tab's buffer, unnamed with a filetype

--- Three tabs: the boot's, one editing a file and one with an unnamed Lua buffer; the first is current
--- @return tests.search-tabs.Fixture
local function three_tabs()
  t.tab()
  local file = t.file('notes.txt', { 'one', 'two' })
  t.tab()
  local scratch = t.buffer('lua', { 'return {}' })
  vim.cmd('1tabnext')
  return { tabs = vim.api.nvim_list_tabpages(), file = file, scratch = scratch }
end

--- @param items { tab: integer, label: string }[]
--- @param field 'tab' | 'label'
--- @return any[]
local function pluck(items, field)
  return vim.tbl_map(function(item)
    return item[field]
  end, items)
end

--- @param picker snacks.Picker
--- @return boolean
local function lists_every_tab(picker)
  return #picker:items() == #vim.api.nvim_list_tabpages()
end

--- Open Snacks.picker.tabs() and wait until it lists every tab
--- @return snacks.Picker
local function open_picker()
  return t.open_picker(function()
    Snacks.picker.tabs()
  end, 'tabs', lists_every_tab, 'the tabs picker to list every tab')
end

--- Put the list cursor on the item of `tab`
--- @param picker snacks.Picker
--- @param tab integer
--- @return snacks.picker.Item
local function select_tab(picker, tab)
  for idx, item in ipairs(picker:items()) do
    if item.tab == tab then
      picker.list:move(idx, true)
      t.eq(picker:current().tab, tab, 'the cursor is on the tab')
      return item
    end
  end
  error(string.format('no item lists tab %d', tab))
end

--- Leave insert mode, as a normal-mode key in the input window would find it
local function normal_mode()
  vim.cmd.stopinsert()
  t.wait_for(function()
    return vim.fn.mode() == 'n'
  end, 'normal mode')
end

--- Press `lhs` in `mode` in one of the picker's windows
--- @param picker snacks.Picker
--- @param win 'input' | 'list'
--- @param mode string
--- @param lhs string
local function press(picker, win, mode, lhs)
  t.map_callback(mode, lhs, picker[win].win.buf)()
end

--- @class tests.search-tabs.Row
--- @field text string The row's text, without the icons drawn over it
--- @field highlighted table<string, string> The text each highlight group covers
--- @field label_end integer The column the label's highlight ends at
--- @field icon_col integer The column the file icon is drawn at

--- The list window's rendered rows, one per listed item
--- @param picker snacks.Picker
--- @return tests.search-tabs.Row[]
local function rendered_rows(picker)
  local buf = t.ok(picker.list.win.buf, 'the list window has a buffer')
  local lines = vim.api.nvim_buf_get_lines(buf, 0, #picker:items(), false)
  local rows = vim.tbl_map(function(line)
    return { text = line, highlighted = {} }
  end, lines)

  local marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })
  for _, mark in ipairs(marks) do
    -- Asked with details, so every mark carries them
    local details = t.ok(mark[4], 'the mark has details')
    local row, col = rows[mark[2] + 1], mark[3]
    if row and details.virt_text then
      row.icon_col = row.icon_col or col
    elseif row and details.hl_group and details.end_col then
      row.highlighted[details.hl_group] = row.text:sub(col + 1, details.end_col)
      if details.hl_group == 'SnacksPickerTabName' then
        row.label_end = details.end_col
      end
    end
  end
  return rows
end

t.test("the picker lists every tab in order, with its label and its window's buffer", function()
  local fixture = three_tabs()
  local origin_buf = vim.api.nvim_get_current_buf()
  local items = open_picker():items()

  t.eq(pluck(items, 'tab'), fixture.tabs, 'one item per tab')
  t.eq(pluck(items, 'label'), { 'tab-1', 'tab-2', 'tab-3' }, 'the labels')
  t.eq(items[1].buf, origin_buf, 'the current tab lists the window the picker opened from')
  t.eq(items[2].buf, fixture.file, "the second tab's buffer")
  t.eq(items[2].file, vim.api.nvim_buf_get_name(fixture.file), 'a named buffer lists its file')
  t.eq(items[3].buf, fixture.scratch, "the third tab's buffer")
  t.eq(items[3].file, '[Scratch]', 'an unnamed buffer lists as [Scratch]')
  t.eq(items[3].filetype, 'lua', 'the filetype of its buffer')
  t.ok(items[3].text:find('tab-3', 1, true), 'the label is searchable')
end)

t.test('labels pad to the widest one, so a codediff tab keeps the file column aligned', function()
  local fixture = three_tabs()
  -- A codediff session on the second tab, as is_codediff_tab finds one
  t.set(package.loaded, 'codediff.ui.lifecycle', {
    get_session = function(tab)
      return tab == fixture.tabs[2] and {} or nil
    end,
  })
  local picker = open_picker()

  t.eq(tabs.label(fixture.tabs[2]), 'codediff-2', "the statusline's label for the codediff tab")
  t.eq(
    pluck(picker:items(), 'label'),
    { 'tab-1     ', 'codediff-2', 'tab-3     ' },
    'the padded labels'
  )
end)

t.test("a row shows the tab's label, then the buffers source's row for its buffer", function()
  local fixture = three_tabs()
  vim.api.nvim_buf_set_lines(fixture.file, 0, 1, false, { 'changed' })
  local picker = open_picker()
  local rows = rendered_rows(picker)
  local modified = Conf.icons.file_status.MODIFIED

  for idx, item in ipairs(picker:items()) do
    local row = rows[idx]
    t.eq(row.highlighted.SnacksPickerTabName, item.label, 'the label, in its color')
    t.eq(row.icon_col, row.label_end + 2, "two columns part the label from the buffer's icon")
  end
  t.ok(rows[1].text:find('[Scratch]', 1, true), "the first tab's unnamed buffer")
  t.eq(rows[1].highlighted.ModifiedIndicator, nil, 'an unmodified buffer has no mark')
  t.ok(rows[2].text:find('notes.txt', 1, true), "the second tab's file")
  t.eq(rows[2].highlighted.ModifiedIndicator, modified, 'a modified buffer is marked')
  t.eq(rows[3].highlighted.SnacksPickerFileType, 'lua', "an unnamed buffer's filetype")
end)

t.test('<CR> closes the picker and switches to the tab under the cursor', function()
  local fixture = three_tabs()
  local picker = open_picker()

  select_tab(picker, fixture.tabs[3])
  press(picker, 'input', 'i', '<CR>')
  t.wait_for(function()
    return vim.api.nvim_get_current_tabpage() == fixture.tabs[3]
  end, "the input's <CR> to switch to the third tab")
  t.ok(picker.closed, 'the picker is closed')

  picker = open_picker()
  select_tab(picker, fixture.tabs[2])
  normal_mode()
  press(picker, 'list', 'n', '<CR>')
  t.wait_for(function()
    return vim.api.nvim_get_current_tabpage() == fixture.tabs[2]
  end, "the list's <CR> to switch to the second tab")
  t.ok(picker.closed, 'the picker is closed')
end)

t.test('x, <C-x> and dd close the tab under the cursor and list the rest', function()
  three_tabs()
  -- One tab to close per key press
  t.tab()
  t.tab()
  vim.cmd('1tabnext')
  local all = vim.api.nvim_list_tabpages()
  local origin_buf = vim.api.nvim_get_current_buf()
  local picker = open_picker()

  local presses = {
    { 'input', 'n', 'x' },
    { 'input', 'n', '<C-x>' },
    { 'input', 'i', '<C-x>' },
    { 'list', 'n', 'dd' },
  }
  for idx, keys in ipairs(presses) do
    local target = all[#all - idx + 1]
    local what = string.format('%s %s in the %s', keys[2], keys[3], keys[1])
    select_tab(picker, target)
    press(picker, keys[1], keys[2], keys[3])
    t.wait_for(function()
      return #picker:items() == #all - idx
    end, string.format('the list to drop the tab %s closed', what))
    t.eq(vim.api.nvim_tabpage_is_valid(target), false, what .. ' closes the tab')
    t.ok(not picker.closed, what .. ' keeps the picker open')
  end
  t.eq(pluck(picker:items(), 'tab'), { all[1] }, 'the tab left is listed')
  -- Refreshed with the input focused: the current tab still lists the window under the picker
  t.eq(picker:items()[1].buf, origin_buf, "the tab left lists its own window's buffer")
end)

t.test('x on the current tab closes it and resumes the picker where nvim lands', function()
  local fixture = three_tabs()
  vim.api.nvim_set_current_tabpage(fixture.tabs[2])
  local picker = open_picker()

  select_tab(picker, fixture.tabs[2])
  normal_mode()
  press(picker, 'input', 'n', 'x')
  local resumed =
    t.await_picker('tabs', lists_every_tab, 'the resumed picker to list the two tabs left')

  t.eq(vim.api.nvim_tabpage_is_valid(fixture.tabs[2]), false, 'the current tab closed')
  t.ok(resumed ~= picker, 'a new picker resumed the closed one')
  t.eq(pluck(resumed:items(), 'tab'), { fixture.tabs[1], fixture.tabs[3] }, 'the listed tabs')
end)

t.test('x on the last tab keeps it, warning instead', function()
  local warnings = t.spy(Notifier, 'warn', function() end)
  local picker = open_picker()

  normal_mode()
  press(picker, 'input', 'n', 'x')
  t.eq(#vim.api.nvim_list_tabpages(), 1, 'the last tab stays')
  t.eq(#warnings, 1, 'one warning')
  t.eq(warnings[1][1], 'Cannot close the last tab', 'the warning')
  t.ok(not picker.closed, 'the picker stays open')
end)
