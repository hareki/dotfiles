-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

local icons = require('config.icons')

--- @class utils.notifier
local M = {}

--- @alias utils.notifier.NotifierOpts { title?: string, height_offset?: integer }

--- @alias utils.notifier.MessageChunk { [1]: string, [2]: string } Text and its highlight group
--- @alias utils.notifier.Message string | utils.notifier.MessageChunk[]

--- A highlight group over part of one message line, counted from the message's first line
--- @class utils.notifier.Highlight
--- @field row integer
--- @field col integer
--- @field end_col integer
--- @field group string

-- Whether the buffer's message is markdown, which only renders once a window shows it
local MARKDOWN_KEY = 'notify_markdown'

-- A notification is read, never edited: the line under the cursor (the first one, as the history
-- float opens) stays rendered, where render-markdown would show an editor its markdown syntax
--- @type render.md.partial.UserConfig
local RENDER_CONFIG = {
  anti_conceal = { enabled = false },
  win_options = { concealcursor = { rendered = 'nvc' } },
}

local highlight_ns = vim.api.nvim_create_namespace('utils.notifier')

--- Render the message as markdown in a window showing its buffer, if it is markdown. nvim-notify's
--- `on_open` and the history picker's preview and float call it too: each shows the buffer in its
--- window after the render has run
--- @param win integer
--- @return nil
function M.paint_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.b[buf][MARKDOWN_KEY] then
    local render_markdown = require('render-markdown')
    -- Asked for before the filetype is set: render-markdown keeps the config of its first look at
    -- a buffer, which the FileType handler would take, and renders once this call has returned
    render_markdown.render({ buf = buf, win = win, config = RENDER_CONFIG })
    -- Set while a window shows the buffer, so the FileType handlers' window options (wrap) land
    -- on it instead of the autocmd window
    vim.bo[buf].filetype = 'markdown'
  end
end

--- The render a notification carries, which nvim-notify runs each time it fills its buffer (the
--- toast, a duplicate re-rendering it, the history picker's preview and float): the configured
--- render, then the message's own paint over its plain lines
--- @param highlights? utils.notifier.Highlight[] A chunk message's spans; nil paints it as markdown
--- @return fun(buf: integer, notif: notify.Notification, hl: NotifyBufHighlights, config: table)
local function renderer(highlights)
  return function(buf, notif, hl, config)
    config.render()(buf, notif, hl, config)

    -- A duplicate re-renders over the old highlights
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    for _, span in ipairs(highlights or {}) do
      vim.api.nvim_buf_set_extmark(buf, highlight_ns, span.row, span.col, {
        end_col = span.end_col,
        hl_group = span.group,
      })
    end

    vim.b[buf][MARKDOWN_KEY] = highlights == nil
    -- A duplicate re-renders into the window of the toast it repeats
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      M.paint_window(win)
    end
  end
end

--- Every markdown message carries this one render, which is how a record tells it is one
local markdown_render = renderer()

--- Whether a history record's message is markdown: a string sent through this module
--- @param record notify.Record
--- @return boolean
function M.is_markdown(record)
  return record.render == markdown_render
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

--- Notify with a string rendered as markdown, or chunks keeping their highlight groups
--- @param level integer
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @param send? fun(msg: string, level: integer, opts: table): any Default: vim.notify
--- @return any handle The notification record, or whether vim.notify_once showed it
local function notify(level, msg, opts, send)
  opts = opts or {}

  local text, highlights
  if type(msg) == 'string' then
    text = msg
  else
    text, highlights = normalize_message(msg)
  end

  local on_open
  if opts.height_offset then
    on_open = function(win)
      vim.api.nvim_win_set_height(win, vim.api.nvim_win_get_height(win) + opts.height_offset)
    end
  end

  -- The record keeps its own render, which nvim-notify re-runs for a duplicate and the history
  -- picker; it replaces noice's, whose extra passes paint nothing on a vim.notify message
  return (send or vim.notify)(text, level, {
    title = opts.title or 'Notifier',
    render = highlights and renderer(highlights) or markdown_render,
    on_open = on_open,
  })
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.info(msg, opts)
  return notify(vim.log.levels.INFO, msg, opts)
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.warn(msg, opts)
  return notify(vim.log.levels.WARN, msg, opts)
end

--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
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
  M.warn(msg, { title = 'Debug ' .. icons.tools.DEBUG, height_offset = -1 })
end

return M
