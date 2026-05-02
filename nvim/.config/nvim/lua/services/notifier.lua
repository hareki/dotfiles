-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

---@class services.notifier
local M = {}

---@alias NotifierOpts { level?: number, title?: string, once?: boolean, id?:string, on_open?: fun(), default_hl?: string, height_offset?: integer }

---@alias MessageTuple { [1]: string, [2]?: string }
---@alias MessageChunk string|MessageTuple
---@alias Message string|string[]|MessageChunk[]

-- Per-id notification state. Only populated when opts.id is set, since only
-- id'd notifications are ever replaced (and thus need their old autocmds cleaned
-- up). Notifications without an id rely on the on_close closure for cleanup.
---@type table<string, { handle: any, autocmd_id: integer? }>
local notif_state = {}
local highlight_ns = vim.api.nvim_create_namespace('trouble_notify_hl')

local function apply_win_opts(win)
  local w = vim.wo[win]
  w.conceallevel = 3
  w.concealcursor = 'n'
  w.spell = false
end

---@param handle any
---@return boolean
local function is_notify_record(handle)
  return type(handle) == 'table' and type(handle.id) == 'number'
end

---Return true if tbl looks like a chunk list: { 'txt', { 'txt', 'hl' }, … }.
local function is_chunk_list(tbl)
  if type(tbl) ~= 'table' then
    return false
  end
  for _, v in ipairs(tbl) do
    if type(v) ~= 'string'
      and (type(v) ~= 'table' or type(v[1]) ~= 'string' or (v[2] ~= nil and type(v[2]) ~= 'string'))
    then
      return false
    end
  end
  return true
end

---Flatten a tuple-list and build an on_open that restores highlights.
---@param chunks table  list of strings *or* {text, hl} tuples
---@param opts   table? { default_hl?: string }
---@return string plain     flattened text for vim.notify
---@return function on_open callback that reapplies extmarks
local function normalize_message(chunks, opts)
  opts = opts or {}
  local default_hl = opts.default_hl or 'Normal'

  local parts, regions = {}, {}
  local line, col = 0, 0

  for _, item in ipairs(chunks) do
    local text, group
    if type(item) == 'string' then -- bare string
      text, group = item, default_hl
    else -- {text, hl}
      text, group = item[1], item[2] or default_hl
    end
    table.insert(parts, text)

    -- Handle multi-line text by splitting on newlines
    local lines = vim.split(text, '\n', { plain = true })
    for i, line_text in ipairs(lines) do
      local byte_len = #line_text
      if i == 1 then
        -- First line: continues current line
        regions[#regions + 1] = { line, col, col + byte_len, group }
        col = col + byte_len
      else
        -- Subsequent lines: new line starts at col 0
        line = line + 1
        regions[#regions + 1] = { line, 0, byte_len, group }
        col = byte_len
      end
    end
  end
  local plain = table.concat(parts)

  ---reapply the extmarks once the floating window opens
  ---@param win integer
  local function on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)
    apply_win_opts(win)
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      for _, r in ipairs(regions) do
        -- Format: r = { line, start_col, end_col, hl_group }
        if r[2] ~= r[3] then -- Only apply if there's actual content (not empty line)
          vim.api.nvim_buf_set_extmark(buf, highlight_ns, r[1], r[2], {
            end_col = r[3],
            hl_group = r[4],
          })
        end
      end
    end)
  end

  return plain, on_open
end

---Core notification function with rich highlighting and markdown support
---Supports both plain strings and tuple lists for custom highlight groups.
---@param msg string|table Plain message or tuple list like {{text, hl}, ...}
---@param opts table? Notification options (level, title, once, id, on_open, default_hl)
---@return any handle The notification handle for replacement/tracking
function M.notify(msg, opts)
  opts = opts or {}
  local is_markdown = not is_chunk_list(msg)
  local supports_state_tracking = not opts.once

  -- Prepare the message/handler depending on the input shape
  local apply_highlight
  if is_markdown then
    -- Strings/list-of-strings: fall back to Treesitter markdown
    msg = type(msg) == 'table' and table.concat(msg, '\n') or msg
    apply_highlight = function(win)
      apply_win_opts(win)
      local bufnr = vim.api.nvim_win_get_buf(win)
      vim.bo[bufnr].filetype = 'markdown'
      local render_markdown = require('render-markdown')
      render_markdown.render({
        buf = bufnr,
        config = {
          render_modes = true,
        },
      })
    end
  else
    ---@cast msg table
    msg, apply_highlight = normalize_message(msg, opts)
  end

  -- Allow callers to chain their own callback
  local user_on_open = opts.on_open
  -- Local autocmd_id closes over both on_open and on_close
  local autocmd_id

  local function merged_on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)

    if is_markdown then
      vim.b[buf].notify_is_markdown = is_markdown
      vim.bo[buf].filetype = 'markdown'
    end

    if apply_highlight then
      apply_highlight(win)

      autocmd_id = vim.api.nvim_create_autocmd({
        'FileType',
      }, {
        buffer = buf,
        callback = function()
          if not vim.api.nvim_win_is_valid(win) then
            return
          end

          apply_highlight(win)
        end,
        desc = 'Reapply Notifier Highlighting for Duplicate Messages',
      })

      -- Track autocmd in shared state for replace-path cleanup (id'd notifications only)
      if opts.id and notif_state[opts.id] then
        notif_state[opts.id].autocmd_id = autocmd_id
      end
    end

    if user_on_open then
      user_on_open(win)
    end

    if opts.height_offset then
      local h = vim.api.nvim_win_get_height(win)
      pcall(vim.api.nvim_win_set_height, win, h + opts.height_offset)
    end
  end

  local function on_close()
    if autocmd_id then
      pcall(vim.api.nvim_del_autocmd, autocmd_id)
      autocmd_id = nil
    end

    if opts.id then
      notif_state[opts.id] = nil
    end
  end

  -- Clean up old autocmd if we're replacing a notification
  local replace_handle
  if supports_state_tracking and opts.id and notif_state[opts.id] then
    local prev = notif_state[opts.id]
    if is_notify_record(prev.handle) then
      replace_handle = prev.handle
    end
    if prev.autocmd_id then
      pcall(vim.api.nvim_del_autocmd, prev.autocmd_id)
    end
  end

  local ret = vim[opts.once and 'notify_once' or 'notify'](msg, opts.level, {
    replace = replace_handle,
    title = opts.title or 'Notifier',
    on_open = merged_on_open,
    on_close = on_close,
  })

  if supports_state_tracking and opts.id and is_notify_record(ret) then
    notif_state[opts.id] = { handle = ret, autocmd_id = autocmd_id }
  elseif opts.id then
    notif_state[opts.id] = nil
  end

  return ret
end

---Display an info-level notification with optional custom highlights
---@param msg Message String, string array, or tuple list for rich formatting
---@param opts? NotifierOpts Notification options (title, id, on_open, etc.)
---@return any handle The notification handle for replacement/tracking
function M.info(msg, opts)
  return M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.INFO, default_hl = 'NotifyINFOBody' },
      opts or {}
    )
  )
end

---Display a warning-level notification with optional custom highlights
---@param msg Message String, string array, or tuple list for rich formatting
---@param opts? NotifierOpts Notification options (title, id, on_open, etc.)
---@return any handle The notification handle for replacement/tracking
function M.warn(msg, opts)
  return M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.WARN, default_hl = 'NotifyWARNBody' },
      opts or {}
    )
  )
end

---Display an error-level notification with optional custom highlights
---@param msg Message String, string array, or tuple list for rich formatting
---@param opts? NotifierOpts Notification options (title, id, on_open, etc.)
---@return any handle The notification handle for replacement/tracking
function M.error(msg, opts)
  return M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.ERROR, default_hl = 'NotifyERRORBody' },
      opts or {}
    )
  )
end

---Display a debug notification with vim.inspect output in a code block
---@param ... any Values to inspect and display
---@return nil
function M.inspect(...)
  local parts = {}
  if select('#', ...) > 0 then
    local obj = select('#', ...) == 1 and ... or { ... }
    parts[1] = '```lua\n'
    parts[2] = vim.inspect(obj)
    parts[3] = '\n```'
  end
  local msg = table.concat(parts)
  M.warn(msg, { title = 'Debug ' .. Icons.tools.debug, height_offset = -1 })
end

return M
