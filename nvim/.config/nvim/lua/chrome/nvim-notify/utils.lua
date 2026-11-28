--- @module 'features.preview.render-markdown-nvim.utils'
local render_markdown = Defer.on_index('features.preview.render-markdown-nvim.utils')

--- @class chrome.nvim-notify.utils
local M = {}

--- The title the spec's `render` leaves in the buffer: `on_open` sees no hl groups or duplicates
M.TITLE_KEY = 'notify_title_with_hl'

-- Read, never edited: the cursor line stays rendered instead of showing its markdown syntax
--- @type render.md.partial.UserConfig
local RENDER_CONFIG = {
  anti_conceal = { enabled = false },
  win_options = { concealcursor = { rendered = 'nvc' } },
}

--- Wrap a notification window's lines and render a markdown message, which needs the buffer shown
--- @param win integer
--- @param notif notify.Record
--- @return nil
local function paint(win, notif)
  -- A message that is not markdown too, which the markdown filetype's own wrap never reaches
  vim.wo[win][0].wrap = true
  if Notifier.is_markdown(notif) then
    local buf = vim.api.nvim_win_get_buf(win)
    local markdown = require('render-markdown')
    -- Before the filetype: render-markdown keeps the config of its first look at a buffer
    markdown.render({ buf = buf, win = win, config = RENDER_CONFIG })
    -- Set while a window shows it, so FileType window options land there, not the autocmd window
    vim.bo[buf].filetype = 'markdown'
  end
end

--- Dress a window as the notification's toast: the spec's title on its border, then the paint.
--- The history preview only paints, its window being the picker's
--- @param win integer
--- @param notif notify.Record Or the notification nvim-notify renders
--- @return nil
function M.dress(win, notif)
  -- None from a notification sent with a render of its own, which never runs the spec's
  local title = vim.b[vim.api.nvim_win_get_buf(win)][M.TITLE_KEY]
  if title then
    vim.api.nvim_win_set_config(win, { title = title, title_pos = 'center' })
  end
  paint(win, notif)
end

--- Size a dressed window to its wrapped rows, up to the inline popup caps: nvim-notify sizes a
--- toast to its buffer lines, and a duplicate's without the caps
--- @param win integer
--- @return nil
function M.fit(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local max_width, max_height = UI.layout.inline_max_width(), UI.layout.inline_max_height()
  vim.api.nvim_win_set_width(win, math.min(vim.api.nvim_win_get_width(win), max_width))

  -- Only the lines the window has room for, since an inspected table has thousands
  -- A hidden line (a code fence's end) counts a row: its sender's `height_offset` takes it off
  local rows = 0
  for row = 0, math.min(vim.api.nvim_buf_line_count(buf), max_height) - 1 do
    local shown = vim.api.nvim_win_text_height(win, { start_row = row, end_row = row }).all
    rows = rows + math.max(shown, 1)
  end

  vim.api.nvim_win_set_height(win, math.min(rows, max_height) + Notifier.height_offset(buf))
end

--- Render a notification into a buffer of its own, as its toast; the caller shows it, then paints
--- @param notif notify.Record
--- @return notify.OpenedBuffer
local function open_buffer(notif)
  local notify = require('notify')
  local opened = notify.open(notif)
  vim.bo[opened.buffer].bufhidden = 'wipe'
  return opened
end

--- Open a notification in a centered float, sized to its content up to the inline popup caps
--- @param notif notify.Record
--- @return nil
local function open_float(notif)
  local opened = open_buffer(notif)
  local width = math.min(opened.width, UI.layout.inline_max_width())
  local height = math.min(opened.height, UI.layout.inline_max_height())
  local col, row = UI.layout.center(width, height)

  local win = vim.api.nvim_open_win(opened.buffer, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    border = 'rounded',
    style = 'minimal',
  })

  vim.wo[win][0].winhighlight =
    string.format('Normal:%s,FloatBorder:%s', opened.highlights.body, opened.highlights.border)
  M.dress(win, notif)

  -- The paint wraps long lines into rows the float lacks, and it can't scroll to the rest of them
  M.fit(win)
  col, row = UI.layout.center(width, vim.api.nvim_win_get_height(win))
  vim.api.nvim_win_set_config(win, { relative = 'editor', col = col, row = row })
end

--- The picker's previewer: the toast as shown, with the chunk highlights Snacks' text one lacks
--- @param ctx snacks.picker.preview.ctx
--- @return nil
local function preview(ctx)
  local opened = open_buffer(ctx.item.notif)
  ctx.preview:set_buf(opened.buffer)
  -- The preview window's keys, which Snacks only maps on the scratch buffers it makes
  ctx.preview.win:map()
  paint(ctx.win, ctx.item.notif)
end

-- Under treesitter's (90 and up), so a markdown row's own colors show over the body's
local BODY_PRIORITY = 50

local staging_buf --- @type integer?

--- The scratch buffer a row's markdown is parsed in. Not the one Snacks parses `code` in, which
--- has no end of line: the parser reads a heading the text stops in (`# Test`) as an error
--- @return integer
local function staging()
  if not (staging_buf and vim.api.nvim_buf_is_valid(staging_buf)) then
    staging_buf = vim.api.nvim_create_buf(false, true)
  end
  return staging_buf
end

--- A render-markdown mark on a row's line, as the list's extmarks for it
--- @param mark render.md.Mark
--- @param line string
--- @return snacks.picker.Extmark[] extmarks Their columns count from the line's start
local function row_extmarks(mark, line)
  local opts = mark.opts

  -- A heading's background runs to the window's edge, and a mask at a window column cuts it off
  -- past the right pad. A row of the list starts at neither, so its line and a pad carry the color
  if opts.virt_text_win_col then
    return {}
  end
  if opts.hl_eol and opts.end_row == mark.start_row + 1 then
    local pad = string.rep(' ', render_markdown.HEADING_PAD)
    return {
      { col = mark.start_col, end_col = #line, hl_group = opts.hl_group },
      { col = #line, virt_text = { { pad, opts.hl_group } }, virt_text_pos = 'inline' },
    }
  end

  -- A mark reaching into another line is not this row's
  if (opts.end_row or mark.start_row) ~= mark.start_row then
    return {}
  end
  local extmark = vim.tbl_extend('force', opts, { col = mark.start_col })
  extmark.end_row = nil
  return { extmark }
end

--- A markdown message's row: its first line with text, a fence aside, colored as in the preview
--- @param message string[]
--- @return string line
--- @return snacks.picker.Extmark[] marks Their columns count from the line's start
local function markdown_row(message)
  for row, line in ipairs(message) do
    if line:find('%S') and not line:find('^%s*```') then
      -- Parsed down to its line only: an inspected table has thousands more (0.5 s for 15,000)
      local buf = staging()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_slice(message, 1, row))

      local highlights = Snacks.picker.highlight.get_highlights({ buf = buf, lang = 'markdown' })
      local marks = highlights[row] or {}
      for _, mark in ipairs(render_markdown.marks(buf)) do
        if mark.start_row == row - 1 then
          vim.list_extend(marks, row_extmarks(mark, line))
        end
      end
      return line, marks
    end
  end

  return '', {}
end

--- Show nvim-notify's history, newest first: rows and preview as the toast showed the message
--- @return snacks.Picker
function M.show_picker()
  local notify = require('notify')
  local history = notify.history()

  local items = {}
  for index = #history, 1, -1 do
    local notif = history[index]

    items[#items + 1] = {
      notif = notif,
      text = notif.title[1] .. ' ' .. table.concat(notif.message, '\n'),
    }
  end

  return Snacks.picker({
    title = 'Notifications',
    source = 'notify',
    items = items,
    show_empty = true,
    format = function(item)
      local notif = item.notif
      local level_hl = 'Notify' .. notif.level .. 'Title'

      local ret = {
        { os.date('%T', notif.time), 'NotifyLogTime' },
        { ' ' },
        { notif.title[1], 'NotifyLogTitle' },
        { ' ' },
        { notif.icon, level_hl },
        { ' ' },
        { notif.level, level_hl },
        { ' ' },
      }

      -- Built once per item: Snacks formats a row each time the list draws it
      if not item.message_row then
        --- @type string, snacks.picker.Highlight[]
        local line, message_row = notif.message[1] or '', {}
        if Notifier.is_markdown(notif) then
          line, message_row = markdown_row(notif.message)
        end
        message_row[#message_row + 1] = {
          col = 0,
          end_col = #line,
          hl_group = 'Notify' .. notif.level .. 'Body',
          priority = BODY_PRIORITY,
        }
        message_row[#message_row + 1] = { line }
        item.message_row = message_row
      end

      -- A copy: `extend` shifts the columns of the row it is given
      return Snacks.picker.highlight.extend(ret, vim.deepcopy(item.message_row))
    end,
    preview = preview,
    win = {
      preview = {
        wo = { number = false, relativenumber = false },
      },
    },
    confirm = function(picker, item)
      picker:close()
      if item then
        open_float(item.notif)
      end
    end,
  })
end

return M
