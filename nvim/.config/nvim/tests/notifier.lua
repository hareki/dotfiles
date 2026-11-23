-- utils.notifier through nvim-notify: what a notification paints (lines, highlights, markdown,
-- title) in its toast, in the toast a duplicate re-renders, in the <leader>fn picker's row and
-- preview, and in the history float, which the picker opens on confirm

local t = require('tests.lib.helpers')
local notify = require('notify')
local notify_utils = require('chrome.nvim-notify.utils')
local render_markdown_utils = require('features.preview.render-markdown-nvim.utils')

local render_markdown_ns = vim.api.nvim_create_namespace('render-markdown.nvim')

local function dismiss_toasts()
  notify.dismiss({ pending = true, silent = true })
end

--- The text `win` shows of buffer line `lnum`, read off the screen: what the user reads there, with
--- the conceals and virtual text of whoever painted it. Its first screen row, should the line wrap
--- @param win integer
--- @param lnum? integer Default 1
--- @return string
local function shown(win, lnum)
  vim.cmd.redraw()
  local info = vim.fn.getwininfo(win)[1]
  local pos = vim.fn.screenpos(win, lnum or 1, 1)
  local cells = {}
  for col = pos.col, pos.col + info.width - info.textoff - 1 do
    cells[#cells + 1] = vim.fn.screenstring(pos.row, col)
  end
  return vim.trim(table.concat(cells))
end

--- Wait for `win` to show `text` on its first line: render-markdown renders off the event loop
--- @param win integer
--- @param text string
--- @param where string
local function await_shown(win, text, where)
  t.wait_for(function()
    return shown(win) == text
  end, string.format('%s to show %q', where, text))
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

--- The history picker as <leader>fn opens it, with the cursor on `record` and its preview drawn
--- @param record notify.Record
--- @return snacks.Picker picker
--- @return integer preview_buf
--- @return integer preview_win
local function pick_from_history(record)
  -- A toast covers the picker's top right corner, which `shown` would read in place of the list
  dismiss_toasts()
  local picker = t.open_picker(notify_utils.show_picker, 'notify')
  for idx, item in ipairs(picker:items()) do
    if item.notif.id == record.id then
      picker.list:move(idx, true)
    end
  end
  t.eq(picker:current().notif.id, record.id, 'the cursor is on the record')

  local preview_win = t.ok(picker.preview.win.win, 'the picker has no preview window')
  local preview_buf --- @type integer?
  t.wait_for(function()
    preview_buf = vim.api.nvim_win_get_buf(preview_win)
    return vim.deep_equal(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), record.message)
  end, 'the preview of the record')
  --- @cast preview_buf integer

  return picker, preview_buf, preview_win
end

--- The message part of the row the history picker's cursor is on, which is the record's
--- @param picker snacks.Picker
--- @param record notify.Record
--- @return string?
local function row_shown(picker, record)
  local win = t.ok(picker.list.win.win, 'the picker has no list window')
  return shown(win, vim.api.nvim_win_get_cursor(win)[1]):match(record.level .. ' (.*)$')
end

--- The highlight groups the history picker paints over all of `text` in the row its cursor is on
--- @param picker snacks.Picker
--- @param text string
--- @return string[]
local function row_groups(picker, text)
  local list = picker.list.win
  local row = vim.api.nvim_win_get_cursor(list.win)[1] - 1
  local line = vim.api.nvim_buf_get_lines(list.buf, row, row + 1, false)[1]
  local from = t.ok(line:find(text, 1, true), 'the row has no ' .. text) - 1
  local marks = vim.api.nvim_buf_get_extmarks(
    list.buf,
    -1,
    { row, 0 },
    { row, -1 },
    { details = true }
  )

  return vim
    .iter(marks)
    :filter(function(mark)
      local details = mark[4]
      return details.hl_group ~= nil and mark[3] <= from and details.end_col >= from + #text
    end)
    :map(function(mark)
      return mark[4].hl_group
    end)
    :totable()
end

--- The virtual text the history picker puts right after `text` in the row its cursor is on
--- @param picker snacks.Picker
--- @param text string
--- @return table? virt_text
local function row_pad(picker, text)
  local list = picker.list.win
  local row = vim.api.nvim_win_get_cursor(list.win)[1] - 1
  local line = vim.api.nvim_buf_get_lines(list.buf, row, row + 1, false)[1]
  local _, to = line:find(text, 1, true)
  local marks = vim.api.nvim_buf_get_extmarks(
    list.buf,
    -1,
    { row, to },
    { row, to },
    { details = true }
  )

  for _, mark in ipairs(marks) do
    if mark[4].virt_text_pos == 'inline' then
      return mark[4].virt_text
    end
  end
end

--- Whether the history picker paints `text` bold in the row its cursor is on
--- @param picker snacks.Picker
--- @param text string
--- @return boolean
local function row_is_bold(picker, text)
  return vim.iter(row_groups(picker, text)):any(function(group)
    return vim.api.nvim_get_hl(0, { name = group, link = false }).bold == true
  end)
end

--- Confirm the picker's record, which opens it in the history float
--- @param picker snacks.Picker
--- @param record notify.Record
--- @return integer win
--- @return integer buf
local function confirm(picker, record)
  -- The preview is one of them until the picker closes
  local before = floats_showing(record.message)
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

--- Open `record` from the history picker as <leader>fn, then confirm, does
--- @param record notify.Record
--- @return integer win
--- @return integer buf
local function open_from_history(record)
  return confirm(pick_from_history(record), record)
end

--- The highlight spans painted on `buf` outside render-markdown, as { row, col, end_row, end_col,
--- group }, from any namespace: what the user sees, not which module painted it
--- @param buf integer
--- @return table[]
local function highlights(buf)
  return vim
    .iter(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true }))
    :filter(function(mark)
      return mark[4].ns_id ~= render_markdown_ns
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
    local marks = vim.api.nvim_buf_get_extmarks(buf, render_markdown_ns, 0, -1, { details = true })
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

  local picker, preview_buf = pick_from_history(record)
  t.eq(row_shown(picker, record), PIN_LINES[1], 'the history row shows the first line')
  t.eq(highlights(preview_buf), PIN_HIGHLIGHTS, 'the history preview highlights each chunk')
  t.eq(vim.bo[preview_buf].filetype, 'notify', 'the history preview is not markdown')
  picker:action('toggle_preview_focus')
  t.eq(picker:current_win(), 'preview', 'the history preview takes the focus')
  t.press('<Tab>')
  t.eq(picker:current_win(), 'input', 'the history preview has the preview window keys')

  local float, float_buf = confirm(picker, record)
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
  vim.api.nvim_buf_clear_namespace(buf, render_markdown_ns, 0, -1)
  Notifier.warn(MARKDOWN, { title = 'Style Enforcer' })
  t.wait_for(function()
    return vim.api.nvim_win_get_config(win).title[1][1]:find('(x2)', 1, true) ~= nil
  end, 'the duplicate to re-render the toast')
  t.eq(vim.bo[buf].filetype, 'markdown', 'the duplicate keeps the filetype')
  await_markdown(buf, 'the duplicate')

  local picker, preview_buf = pick_from_history(record)
  t.eq(
    row_shown(picker, record),
    'Run stylua on init.lua',
    'the history row conceals the markdown syntax'
  )
  t.ok(
    vim.tbl_contains(row_groups(picker, '`init.lua`'), 'RenderMarkdownCodeInline'),
    'the history row paints the inline code as render-markdown does'
  )
  t.eq(vim.bo[preview_buf].filetype, 'markdown', 'the history preview filetype')
  await_markdown(preview_buf, 'the history preview')

  local float, float_buf = confirm(picker, record)
  t.eq(vim.bo[float_buf].filetype, 'markdown', 'the history float filetype')
  t.eq(vim.wo[float].wrap, true, 'the history float wraps')
  await_markdown(float_buf, 'the history float')
  t.eq(
    vim.api.nvim_win_get_config(float).title,
    expected_title(record, float_buf, 'Style Enforcer (x2)'),
    'the history float has the toast title'
  )
end)

t.test('a bold message reads without its asterisks wherever the history shows it', function()
  t.cleanup(dismiss_toasts)
  local lines = { '**test**' }

  Notifier.info(lines[1])
  await_shown(await_toast(lines), 'test', 'the toast')
  local record = record_of(lines)

  local picker, _, preview = pick_from_history(record)
  await_shown(preview, 'test', 'the history preview')
  t.eq(row_shown(picker, record), 'test', 'the history row')
  t.ok(row_is_bold(picker, lines[1]), 'the history row paints the word bold')

  -- Both put the cursor on the message's first line, which render-markdown leaves raw for an editor
  picker:action('toggle_preview_focus')
  t.eq(shown(preview), 'test', 'the history preview under the cursor')
  await_shown(confirm(picker, record), 'test', 'the history float')
end)

-- A one-word heading is the whole of its message: the parser gets no line under it to end it with
t.test('the history row renders a heading, whatever follows it', function()
  t.cleanup(dismiss_toasts)

  for level, lines in ipairs({ { '# Test' }, { '## Test', '', 'Under the heading' } }) do
    Notifier.info(table.concat(lines, '\n'))
    await_toast(lines)
    local record = record_of(lines)
    local background = string.format('RenderMarkdownH%dBg', level)
    local pad = string.rep(' ', render_markdown_utils.HEADING_PAD)

    local picker = pick_from_history(record)
    local groups = row_groups(picker, lines[1])
    t.ok(
      vim.tbl_contains(groups, string.format('@markup.heading.%d.markdown', level)),
      string.format('the history row colors %q as a heading', lines[1])
    )
    t.ok(vim.tbl_contains(groups, background), 'the history row paints the heading background')

    -- render-markdown's icon for the level, whichever glyph the config gives it
    local row = t.ok(row_shown(picker, record), 'the row shows no message')
    local icon, text = vim.trim(row):match('^(%S+) (.*)$')
    t.eq(text, 'Test', 'the history row shows the heading text after one icon')
    t.ok(not icon:find('#', 1, true), 'the icon stands in place of the heading marker')
    t.eq(row:sub(1, #pad), pad, 'the background starts a pad before the icon')
    t.eq(
      row_pad(picker, lines[1]),
      { { pad, background } },
      'the background ends a pad after the text'
    )
    picker:close()
  end
end)

t.test('the history row of a fenced message shows the first line under the fence', function()
  t.cleanup(dismiss_toasts)
  local lines = { '```lua', '{ 1 }', '```' }

  Notifier.inspect({ 1 })
  await_toast(lines)
  local record = record_of(lines)
  t.eq(row_shown(pick_from_history(record), record), '{ 1 }', 'the row skips the fence')
end)

t.test('a vim.notify message renders as markdown in the toast and the history', function()
  t.cleanup(dismiss_toasts)
  local lines = { 'Saved **nothing**' }

  vim.notify(lines[1], vim.log.levels.INFO, { title = 'Plugin' })
  await_shown(await_toast(lines), 'Saved nothing', 'the toast')
  local record = record_of(lines)

  local picker, preview_buf, preview = pick_from_history(record)
  t.eq(row_shown(picker, record), 'Saved nothing', 'the history row conceals the asterisks')
  t.ok(row_is_bold(picker, 'nothing'), 'the history row paints the word bold')
  t.eq(vim.bo[preview_buf].filetype, 'markdown', 'the history preview filetype')
  await_shown(preview, 'Saved nothing', 'the history preview')
end)

-- lazy.nvim sends its markdown with an `on_open` that starts treesitter in the toast
t.test("a message with its sender's on_open renders as markdown too", function()
  t.cleanup(dismiss_toasts)
  local lazy_util = require('lazy.core.util')
  local lines = { 'Reloaded **nothing**' }

  lazy_util.warn(lines[1])
  await_shown(await_toast(lines), 'Reloaded nothing', 'the toast')
  local record = record_of(lines)

  local picker, _, preview = pick_from_history(record)
  t.eq(row_shown(picker, record), 'Reloaded nothing', 'the history row conceals the asterisks')
  await_shown(preview, 'Reloaded nothing', 'the history preview')
end)

t.test("a vim.notify message in another language's ft stays plain", function()
  t.cleanup(dismiss_toasts)
  local lines = { 'local **x**' }

  vim.notify(lines[1], vim.log.levels.INFO, { title = 'Plugin', ft = 'lua' })
  await_toast(lines)
  local record = record_of(lines)

  local picker, preview_buf, preview = pick_from_history(record)
  t.eq(row_shown(picker, record), lines[1], 'the history row keeps the asterisks')
  t.eq(vim.bo[preview_buf].filetype, 'notify', 'the history preview is not markdown')
  t.eq(shown(preview), lines[1], 'the history preview keeps the asterisks')
end)

-- Why the history picker previews with a buffer of its own: this is the previewer it would use
t.test("render-markdown stays out of the markdown preview of Snacks' text previewer", function()
  local picker = t.open_picker(function()
    Snacks.picker({
      source = 'notifier_text_preview',
      items = { { text = MARKDOWN, preview = { text = MARKDOWN, ft = 'markdown' } } },
      format = 'text',
      preview = 'preview',
    })
  end, 'notifier_text_preview')

  local buf --- @type integer?
  t.wait_for(function()
    buf = vim.api.nvim_win_get_buf(picker.preview.win.win)
    return vim.bo[buf].filetype == 'markdown.snacks_picker_preview'
  end, "Snacks' markdown preview")
  --- @cast buf integer
  -- render-markdown, were it on, would have painted by now
  t.settle(300)
  t.eq(
    vim.api.nvim_buf_get_extmarks(buf, render_markdown_ns, 0, -1, {}),
    {},
    'render-markdown paints nothing'
  )
end)

t.test('height_offset resizes the toast, not the history float', function()
  t.cleanup(dismiss_toasts)
  local lines = { 'Offset by one line' }

  Notifier.info({ { lines[1], 'Normal' } }, { title = 'Offset', height_offset = 1 })
  local win = await_toast(lines)
  t.eq(vim.api.nvim_win_get_height(win), 2, 'the toast is one line taller than its message')

  -- nvim-notify sizes the toast to the message again after a duplicate's render
  Notifier.info({ { lines[1], 'Normal' } }, { title = 'Offset', height_offset = 1 })
  t.wait_for(function()
    return vim.api.nvim_win_get_config(win).title[1][1]:find('(x2)', 1, true) ~= nil
  end, 'the duplicate to re-render the toast')
  t.wait_for(function()
    return vim.api.nvim_win_get_height(win) == 2
  end, 'the duplicate to keep the toast one line taller than its message')

  local float = open_from_history(record_of(lines))
  t.eq(vim.api.nvim_win_get_height(float), 1, 'the history float fits the message')
end)

t.test('the history float shows every row of a line it wraps', function()
  t.cleanup(dismiss_toasts)
  -- Three times the widest the float gets
  local lines = { string.rep('x', 3 * UI.layout.inline_max_width()) }

  Notifier.info(lines[1])
  await_toast(lines)

  local float = open_from_history(record_of(lines))
  t.eq(vim.wo[float].wrap, true, 'the history float wraps the line')
  t.ok(vim.api.nvim_win_get_height(float) > 1, 'the history float is taller than one row')
  t.eq(
    vim.api.nvim_win_get_height(float),
    vim.api.nvim_win_text_height(float, {}).all,
    'the history float has a row for each one the line takes'
  )
end)

--- @param kind string Names the test, and tells its message from the other kind's: nvim-notify
--- takes the same text for a duplicate
--- @param message fun(text: string): utils.notifier.Message
local function test_wrapped_toast(kind, message)
  t.test(string.format('a %s toast has a row for each one a wrapped line takes', kind), function()
    t.cleanup(dismiss_toasts)
    local max_width = UI.layout.inline_max_width()
    -- The first line takes three rows of the widest toast, which nvim-notify sizes to two lines
    local lines = { string.rep('x', 3 * max_width), string.format('The line under a %s one', kind) }
    local msg = message(table.concat(lines, '\n'))

    --- @param win integer
    --- @return boolean
    local function fits(win)
      return vim.api.nvim_win_get_width(win) == max_width
        and vim.api.nvim_win_get_height(win) == vim.api.nvim_win_text_height(win, {}).all
    end

    Notifier.info(msg, { title = 'Wrapped' })
    local win = await_toast(lines)
    t.eq(vim.wo[win].wrap, true, 'the toast wraps the line')
    t.eq(vim.api.nvim_win_get_height(win), 4, 'the toast has the rows of both lines')
    t.ok(fits(win), 'the toast is as wide as its cap and as tall as its text')

    -- nvim-notify sizes the toast to the message again after a duplicate's render, without its caps
    Notifier.info(msg, { title = 'Wrapped' })
    t.wait_for(function()
      return vim.api.nvim_win_get_config(win).title[1][1]:find('(x2)', 1, true) ~= nil
    end, 'the duplicate to re-render the toast')
    t.wait_for(function()
      return fits(win)
    end, 'the duplicate to keep the toast within its cap, with the rows of both lines')
    t.eq(vim.api.nvim_win_get_height(win), 4, 'the duplicate keeps the rows of both lines')

    local float = open_from_history(record_of(lines))
    t.eq(vim.api.nvim_win_get_height(float), 4, 'the history float has the rows of both lines')
  end)
end

test_wrapped_toast('markdown', function(text)
  return text
end)
test_wrapped_toast('chunk', function(text)
  return { { text, 'Normal' } }
end)

-- nvim-notify's own renders draw the title in the buffer, so the spec's leaves the window none
t.test('a message with a render of its own opens its toast and its history float', function()
  t.cleanup(dismiss_toasts)
  local lines = { 'Rendered by the sender' }

  vim.notify(lines[1], vim.log.levels.INFO, { title = 'Plugin', render = 'minimal' })
  local win = await_toast(lines)
  t.eq(vim.api.nvim_win_get_config(win).title, nil, 'the toast has no title on its border')

  local float = open_from_history(record_of(lines))
  t.eq(vim.api.nvim_win_get_config(float).title, nil, 'the history float has none either')
end)
