-- features.search.snacks-nvim.sources.buffers through Snacks.picker.buffers(), and its keys

local t = require('tests.lib.helpers')

--- Four file buffers, edited in order, so the last is current
--- @return table<string, integer> bufs By file name
local function four_files()
  local bufs = {}
  for _, name in ipairs({ 'a.txt', 'b.txt', 'c.txt', 'd.txt' }) do
    bufs[name] = t.file(name, { name })
  end
  return bufs
end

--- Open Snacks.picker.buffers() and wait until it lists every file buffer
--- @return snacks.Picker
local function open_picker()
  return t.open_picker(
    function()
      Snacks.picker.buffers()
    end,
    'buffers',
    function(picker)
      return #picker:items() >= 4
    end,
    'the buffers picker to list the four files'
  )
end

--- The buffers the picker lists, in its order
--- @param picker snacks.Picker
--- @return integer[]
local function listed(picker)
  return vim.tbl_map(function(item)
    return item.buf
  end, picker:items())
end

t.test("modified buffers list first, each group in snacks' own order", function()
  four_files()
  local picker = open_picker()
  local unmodified_order = listed(picker)
  t.close_picker(picker)

  -- The last two in snacks' order, which then move ahead of the rest
  local count = #unmodified_order
  local modified = { [unmodified_order[count - 1]] = true, [unmodified_order[count]] = true }
  for buf in pairs(modified) do
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'changed' })
  end

  local expected = vim.list_extend(
    vim.tbl_filter(function(buf)
      return modified[buf]
    end, unmodified_order),
    vim.tbl_filter(function(buf)
      return not modified[buf]
    end, unmodified_order)
  )
  t.eq(listed(open_picker()), expected, 'the order with the last two modified')
end)

t.test('x in the input deletes the buffer under the cursor', function()
  local bufs = four_files()
  local picker = open_picker()
  local count = #picker:items()

  for idx, item in ipairs(picker:items()) do
    if item.buf == bufs['b.txt'] then
      picker.list:move(idx, true)
    end
  end
  t.eq(picker:current().buf, bufs['b.txt'], 'the cursor is on b.txt')

  vim.cmd.stopinsert()
  t.map_callback('n', 'x', picker.input.win.buf)()
  t.wait_for(function()
    return #picker:items() == count - 1
  end, 'the list to drop the deleted buffer')
  t.eq(vim.bo[bufs['b.txt']].buflisted, false, 'b.txt is deleted')
  t.ok(not vim.list_contains(listed(picker), bufs['b.txt']), 'and no longer listed')
end)
