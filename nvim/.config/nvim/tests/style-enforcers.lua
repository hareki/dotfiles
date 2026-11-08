-- The save pipeline (features.formatting.conform-nvim.style-enforcers): its keys, which load
-- conform.nvim on the first press

local t = require('tests.lib.helpers')

local UNFORMATTED = { 'local   x =1' }
local FORMATTED = { 'local x = 1' }

--- @param mode string
--- @param lhs string
--- @return function callback The callback of the map on lhs
local function map_callback(mode, lhs)
  return t.ok(vim.fn.maparg(lhs, mode, false, true).callback, 'no callback map on ' .. lhs)
end

--- @param buf integer
--- @return string[]
local function file_lines(buf)
  return vim.fn.readfile(vim.api.nvim_buf_get_name(buf))
end

t.test('<A-s> loads conform.nvim on the first press, then formats and saves', function()
  t.eq(package.loaded['conform'], nil, 'conform.nvim loaded before the first press')
  local buf = t.file('first.lua', UNFORMATTED)
  vim.bo[buf].modified = true

  -- lazy.nvim's stub loads the plugin and replays the key into the typeahead, which 'x' drains
  vim.api.nvim_feedkeys(vim.keycode('<A-s>'), 'mx', false)
  t.wait_for(function()
    return not vim.bo[buf].modified
  end, 'the write')

  t.eq(file_lines(buf), FORMATTED, 'the file on disk')
  t.eq(vim.fn.exists(':ConformInfo'), 2, ':ConformInfo after the first save')
  vim.cmd.bwipeout()
end)

t.test('<leader>F formats without saving', function()
  local buf = t.file('no-save.lua', UNFORMATTED)

  map_callback('n', '<leader>F')()
  t.wait_for(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), FORMATTED)
  end, 'the format')
  t.settle(100)

  t.ok(vim.bo[buf].modified, 'the buffer was written')
  t.eq(file_lines(buf), UNFORMATTED, 'the file on disk')
  vim.cmd.bwipeout({ bang = true })
end)

t.test('<F40> formats and saves every modified buffer', function()
  local notices, restore = t.spy(vim, 'notify', function() end)
  local first = t.file('all-1.lua', UNFORMATTED)
  vim.bo[first].modified = true
  local second = t.file('all-2.lua', UNFORMATTED)
  vim.bo[second].modified = true

  map_callback('n', '<F40>')()
  t.wait_for(function()
    return not vim.bo[first].modified and not vim.bo[second].modified
  end, 'both writes')
  t.wait_for(function()
    return #notices > 0
  end, 'the summary')
  restore()

  t.eq(file_lines(first), FORMATTED, 'the first file')
  t.eq(file_lines(second), FORMATTED, 'the second file')
  t.eq(notices[1][2], vim.log.levels.INFO, 'the summary level')
  vim.cmd('bwipeout ' .. first .. ' ' .. second)
end)
