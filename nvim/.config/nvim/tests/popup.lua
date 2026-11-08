-- utils.popup.link: what closes a linked popup, and the source buffer's keys it lends and returns

local t = require('tests.lib.helpers')
local popup = require('utils.popup')

--- A float over the current window, which stays current
--- @return integer win
local function open_float()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'popup' })
  return vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = 1,
    col = 1,
    width = 10,
    height = 1,
  })
end

--- A source buffer of three lines with the cursor on the first, alone in the tab
--- @return integer buf
--- @return integer win
local function source()
  vim.cmd.tabnew()
  local buf = t.buffer(nil, { 'one', 'two', 'three' })
  return buf, vim.api.nvim_get_current_win()
end

--- @param buf integer
--- @param lhs string
--- @return string? desc nil when the buffer has no map on lhs
local function buf_map_desc(buf, lhs)
  local map = t.keymap('n', lhs, buf)
  return map and (map.desc or '')
end

t.test('cursor_moved closes it once the cursor leaves its position', function()
  local buf, win = source()
  local float = open_float()
  local closes = 0
  popup.link(float, {
    name = 'Probe',
    close_on = { cursor_moved = true },
    on_close = function()
      closes = closes + 1
    end,
  })

  -- Re-entering the source fires CursorMoved at the same position
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
  t.ok(vim.api.nvim_win_is_valid(float), 'still open after a CursorMoved in place')

  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after the cursor moved')
  t.eq(closes, 1, 'on_close runs')
  t.eq(buf_map_desc(buf, '<Esc>'), nil, 'the source <Esc> override is released')
  vim.cmd.tabclose()
end)

t.test('focus_left closes it in a third window, not in the popup', function()
  local _, win = source()
  local float = open_float()
  popup.link(float, { name = 'Probe', close_on = { focus_left = true } })

  vim.api.nvim_set_current_win(float)
  t.ok(vim.api.nvim_win_is_valid(float), 'still open with the popup focused')
  vim.api.nvim_set_current_win(win)

  vim.cmd.split()
  vim.cmd.enew()
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after focus left both windows')
  vim.cmd.tabclose()
end)

t.test('mode_changed closes it on a mode change in the source buffer', function()
  local buf = source()
  local float = open_float()
  popup.link(float, { name = 'Probe', close_on = { mode_changed = true } })

  vim.api.nvim_exec_autocmds('ModeChanged', { buffer = buf })
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after a mode change')
  vim.cmd.tabclose()
end)

t.test('closing the popup itself releases the link', function()
  local buf = source()
  local float = open_float()
  local closes = 0
  popup.link(float, {
    name = 'Probe',
    on_close = function()
      closes = closes + 1
    end,
  })
  t.eq(buf_map_desc(buf, '<Esc>'), 'Close Probe', 'the source buffer lends <Esc>')
  t.eq(buf_map_desc(buf, '<Tab>'), 'Focus Probe Window', 'the source buffer lends <Tab>')

  vim.api.nvim_win_close(float, true)
  t.eq(closes, 1, 'on_close runs on WinClosed')
  t.eq(buf_map_desc(buf, '<Esc>'), nil, '<Esc> is returned')
  t.eq(buf_map_desc(buf, '<Tab>'), nil, '<Tab> is returned')
  vim.cmd.tabclose()
end)

t.test("overrides stack and give back the buffer's own map", function()
  local buf = source()
  vim.keymap.set('n', '<Tab>', '<Nop>', { buf = buf, desc = 'Own Tab' })

  local first = open_float()
  local close_first = popup.link(first, { name = 'First' })
  local second = open_float()
  local close_second = popup.link(second, { name = 'Second' })
  t.eq(buf_map_desc(buf, '<Esc>'), 'Close Second', 'the newest link holds <Esc>')

  close_first()
  t.eq(buf_map_desc(buf, '<Esc>'), 'Close Second', 'closing the older one keeps the newer map')
  t.ok(vim.api.nvim_win_is_valid(second), 'the newer popup stays open')

  close_second()
  t.eq(buf_map_desc(buf, '<Esc>'), nil, '<Esc> is returned')
  t.eq(buf_map_desc(buf, '<Tab>'), 'Own Tab', "the buffer's own <Tab> is back")
  vim.cmd.tabclose()
end)
