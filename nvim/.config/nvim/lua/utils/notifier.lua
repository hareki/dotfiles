-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

local icons = require('config.icons')

--- @class utils.notifier
local M = {}

--- `markdown`: render a string message as markdown; without it the string is shown as written
--- @alias utils.notifier.NotifierOpts { title?: string, height_offset?: integer, markdown?: boolean }

--- @alias utils.notifier.MessageChunk { [1]: string, [2]: string } Text and its highlight group
--- @alias utils.notifier.Message string | utils.notifier.MessageChunk[]

--- A highlight group over part of one message line, counted from the message's first line
--- @class utils.notifier.Highlight
--- @field row integer
--- @field col integer
--- @field end_col integer
--- @field group string

-- The `height_offset` of the toast's notification, which the toast's fit adds to its height
local HEIGHT_OFFSET_KEY = 'notify_height_offset'

local highlight_ns = vim.api.nvim_create_namespace('utils.notifier')

--- The render a notification carries: the configured render, then the message's own spans.
--- nvim-notify runs it for the toast, a duplicate, and the history picker's preview and float
--- @module 'notify'
--- @param highlights utils.notifier.Highlight[] A chunk message's spans, none for a string
--- @return fun(buf: integer, notif: notify.Notification, hl: NotifyBufHighlights, config: table)
local function renderer(highlights)
  return function(buf, notif, hl, config)
    config.render()(buf, notif, hl, config)

    -- A duplicate re-renders over the old highlights
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    for _, span in ipairs(highlights) do
      vim.api.nvim_buf_set_extmark(buf, highlight_ns, span.row, span.col, {
        end_col = span.end_col,
        hl_group = span.group,
      })
    end
  end
end

--- Every markdown message carries this one render, which is how a record tells it is one. No spans
--- to paint either: the window showing the message renders its markdown
local markdown_render = renderer({})

--- A string shown as written: no spans to paint
local plain_render = renderer({})

--- Whether a message is markdown: sent with `markdown` through this module, or taken in by `adopt`
--- @param record notify.Record Or the notification nvim-notify renders, which carries it too
--- @return boolean
function M.is_markdown(record)
  return record.render == markdown_render
end

--- The `height_offset` of a toast's notification; 0 in the history, whose buffers no toast opened
--- @param buf integer
--- @return integer
function M.height_offset(buf)
  return vim.b[buf][HEIGHT_OFFSET_KEY] or 0
end

--- Give a `vim.notify` message the markdown render, unless it has a render or a non-markdown `ft`
--- Plugins (lazy.nvim, trouble.nvim) color their markdown from an `on_open`, which history drops
--- @param opts table The opts of the vim.notify call
--- @return nil
function M.adopt(opts)
  if not opts.render and (opts.ft == nil or opts.ft == 'markdown') then
    opts.render = markdown_render
  end
end

--- Flatten a chunk list into its text and the spans its highlight groups cover
--- @param chunks utils.notifier.MessageChunk[]
--- @return string plain
--- @return utils.notifier.Highlight[] highlights
local function normalize_message(chunks)
  local parts, highlights = {}, {}
  local row, col = 0, 0

  for _, chunk in ipairs(chunks) do
    local text, group = chunk[1], chunk[2]
    table.insert(parts, text)

    local lines = vim.split(text, '\n', { plain = true })
    for i, line_text in ipairs(lines) do
      -- The first part continues the current line, the others start a new one
      if i > 1 then
        row, col = row + 1, 0
      end
      if line_text ~= '' then
        highlights[#highlights + 1] =
          { row = row, col = col, end_col = col + #line_text, group = group }
      end
      col = col + #line_text
    end
  end

  return table.concat(parts), highlights
end

--- Notify with a string as written (markdown with `opts.markdown`) or chunks keeping their groups
--- @param level integer
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @param send? fun(msg: string, level: integer, opts: table): any Default: vim.notify
--- @return any handle What vim.notify returned (noice's `{ id }` of its message, nil in a fast
--- event, never nvim-notify's record), or whether vim.notify_once showed it
local function notify(level, msg, opts, send)
  opts = opts or {}

  local text, render
  if type(msg) == 'string' then
    text, render = msg, opts.markdown and markdown_render or plain_render
  else
    local highlights
    text, highlights = normalize_message(msg)
    render = renderer(highlights)
  end

  -- Runs before nvim-notify's own `on_open`, which fits the toast
  local on_open
  if opts.height_offset then
    on_open = function(win)
      vim.b[vim.api.nvim_win_get_buf(win)][HEIGHT_OFFSET_KEY] = opts.height_offset
    end
  end

  -- The record keeps its own render, which nvim-notify re-runs for a duplicate and the history
  -- picker; it replaces noice's, whose extra passes paint nothing on a vim.notify message
  return (send or vim.notify)(text, level, {
    title = opts.title or 'Notifier',
    render = render,
    on_open = on_open,
  })
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle What vim.notify returned
function M.info(msg, opts)
  return notify(vim.log.levels.INFO, msg, opts)
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle What vim.notify returned
function M.warn(msg, opts)
  return notify(vim.log.levels.WARN, msg, opts)
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle What vim.notify returned
function M.error(msg, opts)
  return notify(vim.log.levels.ERROR, msg, opts)
end

--- Like warn, shown once per message text per session
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return boolean shown
function M.warn_once(msg, opts)
  return notify(vim.log.levels.WARN, msg, opts, vim.notify_once)
end

--- @alias utils.notifier.Notify fun(msg: utils.notifier.Message, opts?: utils.notifier.NotifierOpts): any

--- @class utils.notifier.Scoped
--- @field info utils.notifier.Notify
--- @field warn utils.notifier.Notify
--- @field error utils.notifier.Notify

--- The notifier under one title, so a module's calls stop restating it; opts still override
--- @param title string
--- @return utils.notifier.Scoped
function M.scoped(title)
  --- @param notify_fn utils.notifier.Notify
  --- @return utils.notifier.Notify
  local function titled(notify_fn)
    return function(msg, opts)
      return notify_fn(msg, vim.tbl_extend('keep', opts or {}, { title = title }))
    end
  end

  return {
    info = titled(M.info),
    warn = titled(M.warn),
    error = titled(M.error),
  }
end

--- Display a debug notification with vim.inspect output in a code block
--- @param ... any
--- @return nil
function M.inspect(...)
  local msg = ''
  if select('#', ...) > 0 then
    -- Explicit branch: `cond and ... or { ... }` would misroute a falsy single arg
    local obj
    if select('#', ...) == 1 then
      obj = ...
    else
      obj = { ... }
    end
    msg = string.format('```lua\n%s\n```', vim.inspect(obj))
  end
  M.warn(msg, { title = 'Debug ' .. icons.tools.DEBUG, height_offset = -1, markdown = true })
end

return M
