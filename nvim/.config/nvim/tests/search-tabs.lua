-- features.search.snacks-nvim.sources.tabs: the tabs picker's source, driven through the table the
-- module exports and through Snacks.picker.tabs(), which the search fragment registers it for

local t = require('tests.lib.helpers')
local tabs = require('features.search.snacks-nvim.sources.tabs')
local buffers = require('features.search.snacks-nvim.sources.buffers')

--- @class tests.search-tabs.Fixture
--- @field tabs integer[] The tabpages, in order
--- @field file integer The second tab's buffer, editing a file
--- @field scratch integer The third tab's buffer, unnamed with a filetype

--- Close every tab but the first, as a failed test may leave them
local function reset_tabs()
  vim.cmd('silent! 1tabnext')
  vim.cmd('silent! tabonly!')
end

--- Three tabs: the boot's, one editing a file and one with an unnamed Lua buffer; the first is current
--- @return tests.search-tabs.Fixture
local function three_tabs()
  reset_tabs()
  vim.cmd.tabnew()
  local file = t.file('notes.txt', { 'one', 'two' })
  vim.cmd.tabnew()
  local scratch = t.buffer('lua', { 'return {}' })
  vim.cmd('1tabnext')
  return { tabs = vim.api.nvim_list_tabpages(), file = file, scratch = scratch }
end

--- The finder's context for a picker opened from the current window
--- @return snacks.picker.finder.ctx
local function finder_ctx()
  local ctx = {}
  ctx.picker = { main = vim.api.nvim_get_current_win() }
  return ctx
end

-- The source's functions with their own signatures, which its snacks.picker.Config type widens
local finder = tabs.source.finder --[[@as fun(opts: table, ctx: snacks.picker.finder.ctx): features.search.snacks-nvim.sources.tabs.Item[] ]]
local tab_close = tabs.source.actions.tab_close --[[@as fun(picker: snacks.Picker)]]

--- @param items { tab: integer, label: string }[]
--- @param field 'tab' | 'label'
--- @return any[]
local function pluck(items, field)
  return vim.tbl_map(function(item)
    return item[field]
  end, items)
end

--- Highlight chunks with their functions replaced, since snacks builds a `resolve` closure per call
--- @param chunks snacks.picker.Highlight[]
--- @return table[]
local function comparable(chunks)
  return vim.tbl_map(function(chunk)
    return vim.tbl_map(function(value)
      return type(value) == 'function' and '<function>' or value
    end, chunk)
  end, chunks)
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

t.test("the finder lists every tab in order, with its label and its window's buffer", function()
  local fixture = three_tabs()
  local items = finder({}, finder_ctx())

  t.eq(pluck(items, 'tab'), fixture.tabs, 'one item per tab')
  t.eq(pluck(items, 'label'), { 'tab-1', 'tab-2', 'tab-3' }, 'the labels')
  t.eq(items[2].buf, fixture.file, "the second tab's buffer")
  t.eq(items[2].file, vim.api.nvim_buf_get_name(fixture.file), 'a named buffer lists its file')
  t.eq(items[3].buf, fixture.scratch, "the third tab's buffer")
  t.eq(items[3].file, '[Scratch]', 'an unnamed buffer lists as [Scratch]')
  t.eq(items[3].filetype, 'lua', 'the filetype of its buffer')
  t.ok(items[3].text:find('tab-3', 1, true), 'the label is searchable')
  reset_tabs()
end)

t.test('labels pad to the widest one, so a codediff tab keeps the file column aligned', function()
  local fixture = three_tabs()
  local lifecycle = package.loaded['codediff.ui.lifecycle']
  -- A codediff session on the second tab, as is_codediff_tab finds one
  package.loaded['codediff.ui.lifecycle'] = {
    get_session = function(tab)
      return tab == fixture.tabs[2] and {} or nil
    end,
  }
  local ok, items = pcall(finder, {}, finder_ctx())
  local label = tabs.label(fixture.tabs[2])
  package.loaded['codediff.ui.lifecycle'] = lifecycle

  t.ok(ok, tostring(items))
  t.eq(label, 'codediff-2', "the statusline's label for the codediff tab")
  t.eq(pluck(items, 'label'), { 'tab-1     ', 'codediff-2', 'tab-3     ' }, 'the padded labels')
  reset_tabs()
end)

t.test('Snacks.picker.tabs() runs the exported source and maps its keys', function()
  three_tabs()
  local picker = open_picker()

  t.eq(picker.opts.finder, tabs.source.finder, 'the finder')
  t.eq(picker.opts.format, tabs.source.format, 'the format')
  t.eq(picker.opts.actions.confirm, tabs.source.confirm, 'the confirm action')
  t.eq(picker.opts.actions.tab_close, tabs.source.actions.tab_close, 'the tab_close action')
  t.map_callback('n', 'x', picker.input.win.buf)
  t.map_callback('n', '<C-X>', picker.input.win.buf)
  t.map_callback('i', '<C-X>', picker.input.win.buf)
  t.map_callback('n', 'dd', picker.list.win.buf)
  t.close_picker(picker)
  reset_tabs()
end)

t.test("format shows the tab's label, then the buffers source's row for its buffer", function()
  three_tabs()
  local picker = open_picker()

  for _, item in ipairs(picker:items()) do
    local row = tabs.source.format(item, picker)
    t.eq(row[1], { item.label, 'SnacksPickerTabName' }, 'the label comes first')
    t.eq(row[2], { '  ' }, 'two spaces part it from the buffer')
    local buffer_row = comparable(buffers.format(item, picker))
    t.eq(comparable({ unpack(row, 3) }), buffer_row, "then the buffer's row")
  end
  t.close_picker(picker)
  reset_tabs()
end)

t.test('confirm closes the picker and switches to the tab under the cursor', function()
  local fixture = three_tabs()
  local picker = open_picker()

  tabs.source.confirm(picker, select_tab(picker, fixture.tabs[3]))
  t.wait_for(function()
    return vim.api.nvim_get_current_tabpage() == fixture.tabs[3]
  end, 'the switch to the third tab')
  t.ok(picker.closed, 'the picker is closed')

  picker = open_picker()
  select_tab(picker, fixture.tabs[2])
  picker:action('confirm')
  t.wait_for(function()
    return vim.api.nvim_get_current_tabpage() == fixture.tabs[2]
  end, "the picker's confirm to switch to the second tab")
  t.ok(picker.closed, 'the picker is closed')
  reset_tabs()
end)

t.test('tab_close closes the tab under the cursor and lists the rest', function()
  local fixture = three_tabs()
  local picker = open_picker()

  select_tab(picker, fixture.tabs[3])
  tab_close(picker)
  t.wait_for(function()
    return #picker:items() == 2
  end, 'the list to drop the closed tab')
  t.eq(vim.api.nvim_list_tabpages(), { fixture.tabs[1], fixture.tabs[2] }, 'the third tab closed')
  t.eq(pluck(picker:items(), 'tab'), { fixture.tabs[1], fixture.tabs[2] }, 'the listed tabs')
  t.ok(not picker.closed, 'the picker stays open')

  -- The list's dd, on the second tab
  select_tab(picker, fixture.tabs[2])
  t.map_callback('n', 'dd', picker.list.win.buf)()
  t.wait_for(function()
    return #picker:items() == 1
  end, 'dd to close the second tab')
  t.eq(vim.api.nvim_list_tabpages(), { fixture.tabs[1] }, 'only the first tab is left')
  t.close_picker(picker)
  reset_tabs()
end)

t.test('x on the current tab closes it and resumes the picker where nvim lands', function()
  local fixture = three_tabs()
  vim.api.nvim_set_current_tabpage(fixture.tabs[2])
  local picker = open_picker()

  select_tab(picker, fixture.tabs[2])
  normal_mode()
  t.map_callback('n', 'x', picker.input.win.buf)()
  local resumed =
    t.await_picker('tabs', lists_every_tab, 'the resumed picker to list the two tabs left')

  t.eq(vim.api.nvim_tabpage_is_valid(fixture.tabs[2]), false, 'the current tab closed')
  t.ok(resumed ~= picker, 'a new picker resumed the closed one')
  t.eq(pluck(resumed:items(), 'tab'), { fixture.tabs[1], fixture.tabs[3] }, 'the listed tabs')
  t.close_picker(resumed)
  reset_tabs()
end)

t.test('tab_close keeps the last tab, warning instead', function()
  reset_tabs()
  local warnings, restore = t.spy(Notifier, 'warn', function() end)
  local picker = open_picker()

  local ok, err = pcall(tab_close, picker)
  restore()
  t.ok(ok, tostring(err))
  t.eq(#vim.api.nvim_list_tabpages(), 1, 'the last tab stays')
  t.eq(#warnings, 1, 'one warning')
  t.eq(warnings[1][1], 'Cannot close the last tab', 'the warning')
  t.close_picker(picker)
end)
