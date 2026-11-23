-- features.navigation.harpoon: the pin keys and their four outcomes, the pinned-files picker, and
-- the statusline piece, whose cache the utils' (buffer, length) key and the spec's harpoon
-- extensions invalidate between them

local t = require('tests.lib.helpers')

local levels = vim.log.levels
local PIN_ICON = Conf.icons.tools.PIN

--- harpoon's list for the boot's cwd, emptied when the test ends
--- @return HarpoonList
local function pin_list()
  local harpoon = require('harpoon')
  local list = harpoon:list()
  t.cleanup(function()
    list:clear()
  end)
  return list
end

--- @param lhs string
local function press(lhs)
  t.map_callback('n', lhs)()
end

--- @param list HarpoonList
--- @return table<integer, string> values By slot
local function slots(list)
  local values = {}
  for i = 1, list:length() do
    local item = list:get(i)
    values[i] = item and item.value
  end
  return values
end

--- The pin piece of the statusline: the slots after the pin icon, nil without it
--- @return string?
local function shown_pins()
  local pins = t.statusline():match(vim.pesc(PIN_ICON) .. '%s+([%d%[%] ]+)')
  return pins and vim.trim(pins)
end

--- Wait for the statusline to show `pins` (nil: no pin piece); the redraw t.statusline asks for
--- leaves the piece's cache alone
--- @param pins string?
--- @param msg string
local function await_pins(pins, msg)
  local shown
  local ok = vim.wait(2000, function()
    shown = shown_pins()
    return shown == pins
  end, 10)
  t.ok(ok, string.format('%s: expected %s, got %s', msg, vim.inspect(pins), vim.inspect(shown)))
end

t.test('a pin key adds the file to an empty slot', function()
  local list = pin_list()
  local notices = t.notices()
  t.file('first.txt', { 'first' })

  press('<leader>H1')
  t.eq(slots(list), { 'first.txt' }, 'the pins')
  t.eq(notices, {
    { level = levels.INFO, title = 'Pin', msg = 'Added first.txt\ninto slot 1' },
  }, 'the notices')
end)

t.test('a pin warns when the file is already there, moves it, or replaces another', function()
  local list = pin_list()
  t.file('a.txt', { 'a' })
  press('<leader>H1')
  local notices = t.notices()

  press('<leader>H1')
  t.eq(slots(list), { 'a.txt' }, 'the pins after pinning to the same slot')
  press('<leader>H2')
  t.eq(slots(list), { nil, 'a.txt' }, 'the pins after pinning to another slot')
  t.file('b.txt', { 'b' })
  press('<leader>H2')
  t.eq(slots(list), { nil, 'b.txt' }, 'the pins after pinning another file to the slot')

  t.eq(notices, {
    { level = levels.WARN, title = 'Pin', msg = 'a.txt\nis already in slot 1' },
    { level = levels.WARN, title = 'Pin', msg = 'Moved a.txt\nfrom slot 1 to 2' },
    { level = levels.WARN, title = 'Pin', msg = 'Replaced a.txt\nwith b.txt\nfor slot 2' },
  }, 'the notices')
end)

t.test('a go key opens the file in its slot', function()
  pin_list()
  local a = t.file('go-a.txt', { 'a' })
  press('<leader>H3')
  t.file('go-b.txt', { 'b' })

  press('<leader>3')
  t.eq(vim.api.nvim_get_current_buf(), a)
end)

t.test('the picker key tells an empty list, opening nothing', function()
  pin_list()
  local notices = t.notices()

  press('<leader>fp')
  t.eq(notices, { { level = levels.INFO, title = 'Pin', msg = 'Pin list is empty' } })
  t.eq(Snacks.picker.get({ source = 'harpoon' }), {}, 'the open pickers')
end)

t.test('the picker lists the pins by slot, removes the selected one and opens one', function()
  local list = pin_list()
  local a = t.file('pick-a.txt', { 'a' })
  press('<leader>H1')
  t.file('pick-c.txt', { 'c' })
  press('<leader>H3')

  local picker = t.open_picker(function()
    press('<leader>fp')
  end, 'harpoon')
  local function listed()
    return vim.tbl_map(function(item)
      return { item.harpoon_idx, item.file }
    end, picker:items())
  end
  t.eq(listed(), { { 1, 'pick-a.txt' }, { 3, 'pick-c.txt' } }, 'the items')
  t.eq(
    t.ok(t.keymap('n', 'x', picker.input.win.buf), 'no x in the input').desc,
    'Remove from Pin List',
    'the x key'
  )

  picker.list:move(1)
  picker:action('remove_harpoon_item')
  t.wait_for(function()
    return #picker:items() == 1
  end, 'the picker to drop the removed pin')
  t.eq(slots(list), { 'pick-a.txt' }, 'the pins after removing the second item')
  t.eq(listed(), { { 1, 'pick-a.txt' } }, 'the items after the removal')

  picker:action('confirm')
  t.wait_for(function()
    return picker.closed
  end, 'the picker to close')
  t.eq(vim.api.nvim_get_current_buf(), a, 'the buffer after confirm')
end)

t.test('the statusline marks the current pin, and follows a replace or a removal', function()
  pin_list()
  t.file('status-a.txt', { 'a' })
  press('<leader>H1')
  t.file('status-b.txt', { 'b' })
  press('<leader>H2')
  await_pins('1 [2]', 'the pins from the second file')

  -- Pinned in place of another file: the slot count stays, so the spec's REPLACE hook refreshes it
  t.file('status-c.txt', { 'c' })
  await_pins('1 2', 'the pins from an unpinned file')
  press('<leader>H1')
  await_pins('[1] 2', 'the pins after replacing the first')

  -- Removed short of the last slot: the count stays, so the spec's REMOVE hook refreshes it. The
  -- piece is drawn with the picker focused first, the cache key then the picker's own buffer
  local picker = t.open_picker(function()
    press('<leader>fp')
  end, 'harpoon')
  await_pins('1 2', 'the pins with the picker focused')
  picker:action('remove_harpoon_item')
  await_pins('2', 'the pins after removing the first')
  t.close_picker(picker)

  press('<leader>H2')
  await_pins('[2]', 'the pins after replacing the last')
end)
