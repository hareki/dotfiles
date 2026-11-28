-- features.diagnostics.trouble-nvim: grep results sent with <C-t> keep their treesitter highlights

local t = require('tests.lib.helpers')

--- Grep the boot's cwd for `search` and send the results to Trouble with the picker's <C-t>
--- @param search string
--- @param count integer The matches to wait for
--- @return integer win The Trouble list
local function grep_to_trouble(search, count)
  local picker = t.open_picker(
    function()
      Snacks.picker.grep({ search = search })
    end,
    'grep',
    function(picker)
      return #picker:items() == count
    end,
    string.format('grep to list %d matches of %q', count, search)
  )

  t.map_callback('i', '<C-t>', picker.input.win.buf)()
  return t.await_trouble()
end

--- The highlights the screen draws two texts of a row with, nil until `win` shows the row
--- @param win integer
--- @param row string The row's text, as grep matched it
--- @param text string
--- @param other string
--- @return integer? attr
--- @return integer? other_attr
local function drawn_attrs(win, row, text, other)
  vim.cmd.redraw()
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
  for lnum, line in ipairs(lines) do
    local start = line:find(row, 1, true)
    if start then
      local function attr(part)
        local col = t.ok(line:find(part, start, true), part .. ' is on the row')
        local pos = vim.fn.screenpos(win, lnum, col)
        return vim.fn.screenattr(pos.row, pos.col)
      end
      return attr(text), attr(other)
    end
  end
end

--- Wait for `row` to draw two of its texts in different highlights, as a parsed row does: Trouble
--- attaches its parsers off the event loop
--- @param win integer
--- @param row string
--- @param text string
--- @param other string
local function await_distinct(win, row, text, other)
  t.wait_for(function()
    local attr, other_attr = drawn_attrs(win, row, text, other)
    return attr ~= nil and attr ~= other_attr
  end, string.format('%q and %q to draw in different highlights', text, other))
end

t.test('rows of every language keep their treesitter highlights', function()
  t.write('notes.lua', { 'local needle = 42' })
  t.write('notes.md', { 'a needle in `code`' })

  local win = grep_to_trouble('needle', 2)

  await_distinct(win, 'local needle = 42', 'local', 'needle')
  await_distinct(win, 'a needle in `code`', 'code', 'a needle')
end)

t.test('a second list sent to the open Trouble list is highlighted too', function()
  t.write('first.lua', { 'local first = 1' })
  -- More rows than the first list: with as many, the rows draw from the first list's trees
  t.write('second.lua', { 'local second = 2', 'local second_too = 3' })

  local win = grep_to_trouble('first', 1)
  await_distinct(win, 'local first = 1', 'local', 'first')

  win = grep_to_trouble('second', 2)
  await_distinct(win, 'local second = 2', 'local', 'second')
end)

t.test('e on a grep row jumps to its match, as <CR> does', function()
  t.write('jump.lua', { 'local before = 1', 'local target = 2' })

  local win = grep_to_trouble('target', 1)
  t.focus_trouble_row(win, 'local target = 2')
  t.press('e')

  -- Trouble runs an action once the list settles, not in the key's own call
  t.wait_for(function()
    return vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'jump.lua'
  end, 'e to jump to the file of the row')
  t.eq(vim.api.nvim_win_get_cursor(0), { 2, 6 })
end)
