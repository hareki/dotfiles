-- utils.notifier through nvim-notify: what a notification paints (lines, highlights, markdown,
-- title) in its toast, in the toast a duplicate re-renders and in the history float, which the
-- <leader>fn picker opens on confirm

local t = require('tests.lib.helpers')
local notify = require('notify')
local notify_utils = require('chrome.nvim-notify.utils')

local RENDER_MARKDOWN_NS = vim.api.nvim_create_namespace('render-markdown.nvim')

local function dismiss_toasts()
  notify.dismiss({ pending = true, silent = true })
end

--- The floats showing exactly `lines`
--- @param lines string[]
--- @return integer[]
local function floats_showing(lines)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if
      vim.api.nvim_win_get_config(win).relative ~= ''
      and vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines)
    then
      wins[#wins + 1] = win
    end
  end
  return wins
end

--- The toast showing `lines`, once nvim-notify has opened it
--- @param lines string[]
--- @return integer win
--- @return integer buf
local function await_toast(lines)
  local win --- @type integer?
  t.wait_for(function()
    win = vim.iter(floats_showing(lines)):find(function(candidate)
      return vim.api.nvim_win_get_config(candidate).zindex == Conf.zindex.NOTIFY
    end)
    return win ~= nil
  end, 'the toast of ' .. vim.inspect(lines))
  --- @cast win integer
  return win, vim.api.nvim_win_get_buf(win)
end

--- The newest history record showing `lines`
--- @param lines string[]
--- @return notify.Record
local function record_of(lines)
  local history = notify.history()
  for index = #history, 1, -1 do
    if vim.deep_equal(history[index].message, lines) then
      return history[index]
    end
  end
  error('no history record shows ' .. vim.inspect(lines))
end

--- Open `record` from the history picker as <leader>fn, then confirm, does
--- @param record notify.Record
--- @return integer win
--- @return integer buf
local function open_from_history(record)
  local before = floats_showing(record.message)
  local picker = t.open_picker(notify_utils.show_picker, 'notify')
  for idx, item in ipairs(picker:items()) do
    if item.notif.id == record.id then
      picker.list:move(idx, true)
    end
  end
  t.eq(picker:current().notif.id, record.id, 'the cursor is on the record')
  picker:action('confirm')

  local win --- @type integer?
  t.wait_for(function()
    win = vim.iter(floats_showing(record.message)):find(function(candidate)
      return not vim.tbl_contains(before, candidate)
    end)
    return win ~= nil
  end, 'the history float')
  --- @cast win integer
  t.cleanup(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end)
  return win, vim.api.nvim_win_get_buf(win)
end

--- The highlight spans painted on `buf` outside render-markdown, as { row, col, end_row, end_col,
--- group }, from any namespace: what the user sees, not which module painted it
--- @param buf integer
--- @return table[]
local function highlights(buf)
  return vim
    .iter(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true }))
    :filter(function(mark)
      return mark[4].ns_id ~= RENDER_MARKDOWN_NS
    end)
    :map(function(mark)
      return { mark[2], mark[3], mark[4].end_row, mark[4].end_col, mark[4].hl_group }
    end)
    :totable()
end

--- Wait for render-markdown, which renders off the event loop, to paint MARKDOWN's inline code
--- @param buf integer
--- @param where string
local function await_markdown(buf, where)
  t.wait_for(function()
    local marks = vim.api.nvim_buf_get_extmarks(buf, RENDER_MARKDOWN_NS, 0, -1, { details = true })
    return vim.iter(marks):any(function(mark)
      local details = mark[4]
      return details.hl_group == 'RenderMarkdownCodeInline'
        and mark[2] == 0
        and mark[3] == 18
        and details.end_row == 0
        and details.end_col == 28
    end)
  end, string.format('render-markdown to paint the inline code in %s', where))
end

--- The window's title: the record's icon and title, in the level's title group of `buf`
--- @param record notify.Record
--- @param buf integer
--- @param title string
--- @return table
local function expected_title(record, buf, title)
  return {
    { string.format(' %s %s ', record.icon, title), 'Notify' .. record.level .. 'Title' .. buf },
  }
end

local PIN_CHUNKS = {
  { 'Pinned ', 'Normal' },
  { 'notifier.lua', 'Title' },
  { '\nto slot ', 'Comment' },
  { '3', 'Error' },
}
local PIN_LINES = { 'Pinned notifier.lua', 'to slot 3' }
local PIN_HIGHLIGHTS = {
  { 0, 0, 0, 7, 'Normal' },
  { 0, 7, 0, 19, 'Title' },
  { 1, 0, 1, 8, 'Comment' },
  { 1, 8, 1, 9, 'Error' },
}

local MARKDOWN = 'Run **stylua** on `init.lua`'

t.test('a chunk message keeps its highlights in the toast, a duplicate and the history', function()
  t.cleanup(dismiss_toasts)
  local pin = Notifier.scoped('Pin')

  pin.info(PIN_CHUNKS)
  local win, buf = await_toast(PIN_LINES)
  local record = record_of(PIN_LINES)
  t.eq(highlights(buf), PIN_HIGHLIGHTS, 'the toast highlights each chunk, across both lines')
  t.eq(vim.bo[buf].filetype, 'notify', 'the toast is not markdown')
  t.eq(
    vim.api.nvim_win_get_config(win).title,
    expected_title(record, buf, 'Pin'),
    'the toast title'
  )

  pin.info(PIN_CHUNKS)
  t.wait_for(function()
    return vim.api.nvim_win_get_config(win).title[1][1]:find('(x2)', 1, true) ~= nil
  end, 'the duplicate to re-render the toast')
  t.eq(vim.api.nvim_win_get_buf(win), buf, 'the duplicate renders into the same toast')
  t.eq(highlights(buf), PIN_HIGHLIGHTS, 'the duplicate keeps the highlights')
  t.eq(
    vim.api.nvim_win_get_config(win).title,
    expected_title(record, buf, 'Pin (x2)'),
    'the duplicate counts itself in the title'
  )

  local float, float_buf = open_from_history(record)
  t.eq(highlights(float_buf), PIN_HIGHLIGHTS, 'the history float highlights each chunk')
  t.eq(
    vim.api.nvim_win_get_config(float).title,
    expected_title(record, float_buf, 'Pin (x2)'),
    'the history float has the toast title'
  )
end)

t.test('a string message renders as markdown in the toast, a duplicate and the history', function()
  t.cleanup(dismiss_toasts)

  Notifier.warn(MARKDOWN, { title = 'Style Enforcer' })
  local win, buf = await_toast({ MARKDOWN })
  local record = record_of({ MARKDOWN })
  t.eq(vim.bo[buf].filetype, 'markdown', 'the toast filetype')
  t.eq(vim.wo[win].wrap, true, 'the toast wraps, as markdown buffers do')
  await_markdown(buf, 'the toast')
  t.eq(highlights(buf), {}, 'no chunk highlights')
  t.eq(
    vim.api.nvim_win_get_config(win).title,
    expected_title(record, buf, 'Style Enforcer'),
    'the toast title'
  )

  -- So the duplicate's render has to paint it again
  vim.api.nvim_buf_clear_namespace(buf, RENDER_MARKDOWN_NS, 0, -1)
  Notifier.warn(MARKDOWN, { title = 'Style Enforcer' })
  t.wait_for(function()
    return vim.api.nvim_win_get_config(win).title[1][1]:find('(x2)', 1, true) ~= nil
  end, 'the duplicate to re-render the toast')
  t.eq(vim.bo[buf].filetype, 'markdown', 'the duplicate keeps the filetype')
  await_markdown(buf, 'the duplicate')

  local float, float_buf = open_from_history(record)
  t.eq(vim.bo[float_buf].filetype, 'markdown', 'the history float filetype')
  t.eq(vim.wo[float].wrap, true, 'the history float wraps')
  await_markdown(float_buf, 'the history float')
  t.eq(
    vim.api.nvim_win_get_config(float).title,
    expected_title(record, float_buf, 'Style Enforcer (x2)'),
    'the history float has the toast title'
  )
end)

t.test('height_offset resizes the toast, not the history float', function()
  t.cleanup(dismiss_toasts)
  local lines = { 'Offset by one line' }

  Notifier.info({ { lines[1], 'Normal' } }, { title = 'Offset', height_offset = 1 })
  local win = await_toast(lines)
  t.eq(vim.api.nvim_win_get_height(win), 2, 'the toast is one line taller than its message')

  local float = open_from_history(record_of(lines))
  t.eq(vim.api.nvim_win_get_height(float), 1, 'the history float fits the message')
end)
