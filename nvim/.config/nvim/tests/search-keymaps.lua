-- features.search.snacks-nvim.sources.keymaps, driven through Snacks.picker.keymaps()

local t = require('tests.lib.helpers')

-- In every probe map's desc, so a picker searching for it lists only those
local MARK = 'Zqxv'

--- Map `lhs` in normal mode until the test ends
--- @param lhs string
--- @param opts vim.keymap.set.Opts
local function map(lhs, opts)
  vim.keymap.set('n', lhs, '<Nop>', opts)
  if not opts.buf then
    t.cleanup(function()
      vim.keymap.del('n', lhs)
    end)
  end
end

--- Give `lhs` a desc through a which-key spec until the test ends
--- @param lhs string
--- @param desc string
local function which_key_desc(lhs, desc)
  local which_key = require('which-key')
  local wk_config = require('which-key.config')
  local count = #wk_config.mappings
  which_key.add({ { lhs, desc = desc } })
  t.cleanup(function()
    for idx = #wk_config.mappings, count + 1, -1 do
      table.remove(wk_config.mappings, idx)
    end
  end)
end

--- Open Snacks.picker.keymaps() searching for MARK, and wait until it lists `count` maps
--- @param count integer
--- @return snacks.Picker
local function open_picker(count)
  return t.open_picker(
    function()
      Snacks.picker.keymaps({ pattern = MARK })
    end,
    'keymaps',
    function(picker)
      return #picker:items() == count
    end,
    string.format('the keymaps picker to list the %d probe maps', count)
  )
end

--- The listed item and rendered row of the map on `lhs`
--- @param picker snacks.Picker
--- @param lhs string
--- @return snacks.picker.Item item
--- @return string row
local function row_of(picker, lhs)
  local wanted = vim.fn.keytrans(vim.keycode(lhs))
  for idx, item in ipairs(picker:items()) do
    if vim.fn.keytrans(item.item.lhs) == wanted then
      local row = vim.api.nvim_buf_get_lines(picker.list.win.buf, idx - 1, idx, false)[1]
      return item, row
    end
  end
  error('no item lists ' .. lhs)
end

t.test("a map without a desc takes its which-key spec's, and noisy maps are left out", function()
  map('<leader>zqa', {})
  which_key_desc('<leader>zqa', MARK .. ' From Which Key')
  map('<leader>zqb', { desc = MARK .. ' blink.cmp' })
  map('<leader>zqc', { desc = MARK .. ' autopairs map key' })
  map('<leader>zqd', { desc = MARK .. ' Own' })

  local picker = open_picker(2)
  local item = row_of(picker, '<leader>zqa')
  t.eq(item.item.desc, MARK .. ' From Which Key', "the which-key spec's desc")
  t.ok(item.text:find('From Which Key', 1, true), 'which is searchable')
  t.eq(row_of(picker, '<leader>zqd').item.desc, MARK .. ' Own', 'a map keeps its own desc')
end)

t.test('a row shows the desc, the buffer of a local map, the lhs and the mode, aligned', function()
  local buf = t.buffer()
  map('<leader>zqa', { desc = MARK .. ' Global' })
  map('<leader>zqb', { buf = buf, desc = MARK .. ' Local' })
  map('<leader>zqc', { desc = MARK .. ' ' .. string.rep('long ', 30) })

  local picker = open_picker(3)
  local _, global = row_of(picker, '<leader>zqa')
  local _, local_row = row_of(picker, '<leader>zqb')
  local _, long = row_of(picker, '<leader>zqc')

  t.ok(global:find(MARK .. ' Global', 1, true), 'the desc')
  t.ok(vim.endswith(global, '<Space>zqa n'), 'the lhs, then the mode, end the row')
  t.ok(not global:find('buf:', 1, true), 'a global map names no buffer')
  t.ok(local_row:find(string.format('buf:%d', buf), 1, true), 'a local map names its buffer')
  t.ok(long:find('…', 1, true), 'a desc too long for its column is truncated')

  local width = vim.api.nvim_strwidth(global)
  t.eq(vim.api.nvim_strwidth(local_row), width, 'rows are as wide whatever their buffer column')
  t.eq(vim.api.nvim_strwidth(long), width, 'and whatever their desc')
  t.ok(width <= vim.api.nvim_win_get_width(picker.list.win.win), 'the row fits the list window')
end)
