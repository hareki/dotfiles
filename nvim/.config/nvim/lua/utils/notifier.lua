-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

---@class utils.notifier
local M = {}

---@alias NotifierOpts { level?: number, title?: string, once?: boolean, id?:string, on_open?: fun(), default_hl?: string }

---@alias MessageTuple { [1]: string, [2]?: string }
---@alias Message string|string[]|MessageTuple[]

---@type table<string, any>
local notif_ids = {}

-- Track autocmd IDs to prevent memory leak when notifications are replaced
---@type table<any, integer|nil>
local notif_autocmds = {}

local function apply_win_opts(win)
  local w = vim.wo[win]
  w.conceallevel = 3
  w.concealcursor = 'n'
  w.spell = false
end

---Return true if tbl looks like { {txt, hl}, {txt, hl}, … }.
local function is_tuple_list(tbl)
  if type(tbl) ~= 'table' then
    return false
  end
  for _, v in ipairs(tbl) do
    if type(v) ~= 'table' or #v < 2 or type(v[1]) ~= 'string' or type(v[2]) ~= 'string' then
      return false
    end
  end
  return true
end

---Flatten a tuple-list and build an on_open that restores highlights.
---@param chunks table  list of strings *or* {text, hl} tuples
---@param opts   table? { default_hl?: string, ns?: string }
---@return string plain     flattened text for vim.notify
---@return function on_open callback that reapplies extmarks
local function normalize_message(chunks, opts)
  opts = opts or {}
  local default_hl = opts.default_hl or 'Normal'
  local ns = vim.api.nvim_create_namespace(opts.ns or 'trouble_notify_hl')

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
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.schedule(function()
      for _, r in ipairs(regions) do
        -- r = {line, start_col, end_col, hl_group}
        if r[2] ~= r[3] then -- Only apply if there's actual content (not empty line)
          vim.api.nvim_buf_set_extmark(buf, ns, r[1], r[2], {
            end_col = r[3],
            hl_group = r[4],
          })
        end
      end
    end)
  end

  return plain, on_open
end

---@param msg  string|table
---@param opts table?
function M.notify(msg, opts)
  opts = opts or {}
  local is_markdown = not is_tuple_list(msg)

  -- Prepare the message/handler depending on the input shape
  local apply_highlight
  if is_markdown then
    -- strings / list-of-strings: fall back to Treesitter markdown
    msg = type(msg) == 'table' and table.concat(msg, '\n') or msg
    apply_highlight = function(win)
      apply_win_opts(win)
      local bufnr = vim.api.nvim_win_get_buf(win)
      vim.bo[bufnr].filetype = 'markdown'
      require('render-markdown').render({
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
  -- Track autocmd_id in a table so it can be shared between on_open and on_close
  local state = { autocmd_id = nil, notif_handle = nil }

  local function merged_on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)

    if is_markdown then
      vim.b[buf].notify_is_markdown = is_markdown
      vim.bo[buf].filetype = 'markdown'
    end

    if apply_highlight then
      apply_highlight(win)

      state.autocmd_id = vim.api.nvim_create_autocmd({
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

      -- Track autocmd ID for cleanup if we have a notification handle
      if state.notif_handle then
        notif_autocmds[state.notif_handle] = state.autocmd_id
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
    if state.autocmd_id then
      pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
      state.autocmd_id = nil
    end

    if state.notif_handle and notif_autocmds[state.notif_handle] then
      notif_autocmds[state.notif_handle] = nil
    end

    -- Clean up notification ID from cache to prevent memory leak
    if opts.id then
      notif_ids[opts.id] = nil
    end
  end

  -- Clean up old autocmd if we're replacing a notification
  if opts.id and notif_ids[opts.id] and notif_autocmds[notif_ids[opts.id]] then
    pcall(vim.api.nvim_del_autocmd, notif_autocmds[notif_ids[opts.id]])
    notif_autocmds[notif_ids[opts.id]] = nil
  end

  local ret = vim[opts.once and 'notify_once' or 'notify'](msg, opts.level, {
    replace = opts.id and notif_ids[opts.id] or nil,
    title = opts.title or 'Notifier',
    on_open = merged_on_open,
    on_close = on_close,
  })

  -- Store handle for tracking
  state.notif_handle = ret

  if opts.id then
    notif_ids[opts.id] = ret
  end

  return ret
end

---@param msg Message
---@param opts? NotifierOpts
function M.info(msg, opts)
  M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.INFO, default_hl = 'NotifyINFOBody' },
      opts or {}
    )
  )
end

---@param msg Message
---@param opts? NotifierOpts
function M.warn(msg, opts)
  M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.WARN, default_hl = 'NotifyWARNBody' },
      opts or {}
    )
  )
end

---@param msg Message
---@param opts? NotifierOpts
function M.error(msg, opts)
  M.notify(
    msg,
    vim.tbl_extend(
      'force',
      { level = vim.log.levels.ERROR, default_hl = 'NotifyERRORBody' },
      opts or {}
    )
  )
end

function M.debug(...)
  local parts = {}
  if select('#', ...) > 0 then
    local obj = select('#', ...) == 1 and ... or { ... }
    parts[1] = '```lua\n'
    parts[2] = vim.inspect(obj)
    parts[3] = '\n```'
  end
  local msg = table.concat(parts)
  M.warn(msg, { title = 'Debug 󰃤', height_offset = -1 })
end

return M
