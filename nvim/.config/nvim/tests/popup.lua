-- utils.popup.link: what closes a linked popup, and the source buffer's keys it lends and returns

local t = require('tests.lib.helpers')
local popup = require('utils.popup')

--- A source buffer of three lines with the cursor on the first, alone in the tab
--- @return integer buf
--- @return integer win
local function source()
  t.tab()
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
  local float = t.float()
  local closes = 0
  popup.link(float, {
    name = 'Probe',
    close_on = { cursor_moved = true },
    on_close = function()
      closes = closes + 1
    end,
  })

  -- Re-entering the source fires CursorMoved at the same position
  vim.api.nvim_exec_autocmds('CursorMoved', { buf = buf })
  t.ok(vim.api.nvim_win_is_valid(float), 'still open after a CursorMoved in place')

  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buf = buf })
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after the cursor moved')
  t.eq(closes, 1, 'on_close runs')
  t.eq(buf_map_desc(buf, '<Esc>'), nil, 'the source <Esc> override is released')
end)

t.test('focus_left closes it in a third window, not in the popup', function()
  local _, win = source()
  local float = t.float()
  popup.link(float, { name = 'Probe', close_on = { focus_left = true } })

  vim.api.nvim_set_current_win(float)
  t.ok(vim.api.nvim_win_is_valid(float), 'still open with the popup focused')
  vim.api.nvim_set_current_win(win)

  vim.cmd.split()
  vim.cmd.enew()
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after focus left both windows')
end)

t.test('mode_changed closes it on a mode change in the source buffer', function()
  local buf = source()
  local float = t.float()
  popup.link(float, { name = 'Probe', close_on = { mode_changed = true } })

  vim.api.nvim_exec_autocmds('ModeChanged', { buf = buf })
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after a mode change')
end)

t.test('closing the popup itself releases the link', function()
  local buf = source()
  local float = t.float()
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
end)

t.test("overrides stack and give back the buffer's own map", function()
  local buf = source()
  vim.keymap.set('n', '<Tab>', '<Nop>', { buf = buf, desc = 'Own Tab' })

  local first = t.float()
  local close_first = popup.link(first, { name = 'First' })
  local second = t.float()
  local close_second = popup.link(second, { name = 'Second' })
  t.eq(buf_map_desc(buf, '<Esc>'), 'Close Second', 'the newest link holds <Esc>')

  close_first()
  t.eq(buf_map_desc(buf, '<Esc>'), 'Close Second', 'closing the older one keeps the newer map')
  t.ok(vim.api.nvim_win_is_valid(second), 'the newer popup stays open')

  close_second()
  t.eq(buf_map_desc(buf, '<Esc>'), nil, '<Esc> is returned')
  t.eq(buf_map_desc(buf, '<Tab>'), 'Own Tab', "the buffer's own <Tab> is back")
end)

--- Give the source buffer an <Esc> of its own, then press the one a popup linked with
--- `esc_passthrough` lends there and run what that press queues
--- @param esc_passthrough boolean
--- @return integer presses How often the buffer's own <Esc> ran
--- @return integer float
local function press_lent_esc(esc_passthrough)
  local buf = source()
  local presses = 0
  vim.keymap.set('n', '<Esc>', function()
    presses = presses + 1
  end, { buf = buf, desc = 'Own Esc' })

  local float = t.float()
  popup.link(float, { name = 'Probe', esc_passthrough = esc_passthrough })
  t.map_callback('n', '<Esc>', buf)()
  vim.api.nvim_feedkeys('', 'x', false)

  t.eq(buf_map_desc(buf, '<Esc>'), 'Own Esc', "the buffer's own <Esc> is back")
  return presses, float
end

t.test('esc_passthrough replays <Esc> to the map the popup covered', function()
  local presses, float = press_lent_esc(true)
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after <Esc>')
  t.eq(presses, 1, "runs of the buffer's own <Esc>")
end)

t.test('without esc_passthrough, <Esc> only closes the popup', function()
  local presses, float = press_lent_esc(false)
  t.eq(vim.api.nvim_win_is_valid(float), false, 'open after <Esc>')
  t.eq(presses, 0, "runs of the buffer's own <Esc>")
end)
