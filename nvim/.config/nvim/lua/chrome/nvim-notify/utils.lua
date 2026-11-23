--- @class chrome.nvim-notify.utils
local M = {}

--- The buffer variable the spec's `render` leaves the title in: nvim-notify renders a toast before
--- it opens its window, and `on_open` gets neither the highlight groups nor the duplicates
M.TITLE_KEY = 'notify_title_with_hl'

--- Render a notification into a buffer of its own, as nvim-notify rendered its toast. The caller
--- shows the buffer in a window, then hands that to `Notifier.paint_window`
--- @param notif notify.Record
--- @return notify.OpenedBuffer
local function open_buffer(notif)
  local notify = require('notify')
  --- @diagnostic disable-next-line: missing-parameter nvim-notify annotates the optional opts as required
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
    title = vim.b[opened.buffer][M.TITLE_KEY],
    title_pos = 'center',
  })

  vim.wo[win][0].winhighlight =
    string.format('Normal:%s,FloatBorder:%s', opened.highlights.body, opened.highlights.border)
  Notifier.paint_window(win)
end

--- The picker's previewer: the notification as its toast showed it. Snacks' text previewer has no
--- chunk highlights, and its markdown never reaches render-markdown (the render-markdown spec opts
--- the `markdown.snacks_picker_preview` filetype out)
--- @param ctx snacks.picker.preview.ctx
--- @return nil
local function preview(ctx)
  local opened = open_buffer(ctx.item.notif)
  ctx.preview:set_buf(opened.buffer)
  -- The preview window's keys, which Snacks only maps on the scratch buffers it makes
  ctx.preview.win:map()
  Notifier.paint_window(ctx.win)
end

-- Under treesitter's (90 and up), so a markdown row's own colors show over the body's
local BODY_PRIORITY = 50

--- What a list row shows of a markdown message: its first line with text, a code fence aside (it
--- names the language of the lines under it), and treesitter's highlights and conceals for that
--- line. render-markdown paints a window on a markdown buffer, which one row of the list is not
--- @param message string[]
--- @return string line
--- @return snacks.picker.Extmark[] marks
local function markdown_row(message)
  local rows = Snacks.picker.highlight.get_highlights({
    code = table.concat(message, '\n'),
    lang = 'markdown',
  })

  for row, line in ipairs(message) do
    if line:find('%S') and not line:find('^%s*```') then
      return line, rows[row] or {}
    end
  end

  return '', {}
end

--- Show nvim-notify's history, newest first: each row its message's first line and the preview
--- the whole message, both as the toast showed it
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

      local line, marks = notif.message[1] or '', {}
      if Notifier.is_markdown(notif) then
        -- Parsed once per item: Snacks formats a row each time the list draws it
        item.markdown_row = item.markdown_row or { markdown_row(notif.message) }
        line, marks = unpack(item.markdown_row)
      end

      local offset = Snacks.picker.highlight.offset(ret)
      ret[#ret + 1] = {
        col = offset,
        end_col = offset + #line,
        hl_group = 'Notify' .. notif.level .. 'Body',
        priority = BODY_PRIORITY,
      }
      for _, mark in ipairs(marks) do
        ret[#ret + 1] = vim.tbl_extend('force', mark, {
          col = mark.col + offset,
          end_col = mark.end_col + offset,
        })
      end
      ret[#ret + 1] = { line }

      return ret
    end,
    preview = preview,
    win = {
      preview = {
        wo = { wrap = true, number = false, relativenumber = false },
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
