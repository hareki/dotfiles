-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

--- @class utils.notifier
local M = {}

--- @alias utils.notifier.NotifierOpts { title?: string, height_offset?: integer }

--- @alias utils.notifier.MessageTuple { [1]: string, [2]?: string }
--- @alias utils.notifier.MessageChunk string | utils.notifier.MessageTuple
--- @alias utils.notifier.Message string | string[] | utils.notifier.MessageChunk[]

local highlight_ns = vim.api.nvim_create_namespace('trouble_notify_hl')

--- Whether tbl is a chunk list ({ 'txt', { 'txt', 'hl' }, ... }), which needs at least one
--- {text, hl} tuple: a table of bare strings is a string[] message, joined as markdown
local function is_chunk_list(tbl)
  if type(tbl) ~= 'table' then
    return false
  end

  local has_tuple = false
  for _, v in ipairs(tbl) do
    if type(v) == 'table' then
      if type(v[1]) ~= 'string' or (v[2] ~= nil and type(v[2]) ~= 'string') then
        return false
      end
      has_tuple = true
    elseif type(v) ~= 'string' then
      return false
    end
  end

  return has_tuple
end

--- Flatten a tuple-list and build an on_open that restores highlights.
--- @param chunks table  list of strings *or* {text, hl} tuples
--- @param default_hl string
--- @return string plain     flattened text for vim.notify
--- @return function on_open callback that reapplies extmarks
local function normalize_message(chunks, default_hl)
  local parts, regions = {}, {}
  local line, col = 0, 0

  for _, item in ipairs(chunks) do
    local text, group
    if type(item) == 'string' then
      text, group = item, default_hl
    else -- {text, hl}
      text, group = item[1], item[2] or default_hl
    end
    table.insert(parts, text)

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

  --- reapply the extmarks once the floating window opens
  --- @param win integer
  local function on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)
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

--- Core notification function with rich highlighting and markdown support
--- @param level integer
--- @param default_hl string Body highlight of a chunk list's plain chunks
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
local function notify(level, default_hl, msg, opts)
  opts = opts or {}
  local is_markdown = not is_chunk_list(msg)

  local apply_highlight
  if is_markdown then
    -- Strings/list-of-strings: fall back to Treesitter markdown
    msg = type(msg) == 'table' and table.concat(msg, '\n') or msg
    apply_highlight = function(win)
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
    --- @cast msg table
    msg, apply_highlight = normalize_message(msg, default_hl)
  end

  local function on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)

    apply_highlight(win)

    -- Relies on `nvim-notify` re-detecting filetype during duplicate render
    vim.api.nvim_create_autocmd('FileType', {
      buffer = buf,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          apply_highlight(win)
        end
      end,
      desc = 'Reapply Notifier Highlighting for Duplicate Messages',
    })

    if opts.height_offset then
      local h = vim.api.nvim_win_get_height(win)
      pcall(vim.api.nvim_win_set_height, win, h + opts.height_offset)
    end
  end

  return vim.notify(msg, level, {
    title = opts.title or 'Notifier',
    on_open = on_open,
  })
end

--- Display an info-level notification with optional custom highlights
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.info(msg, opts)
  return notify(vim.log.levels.INFO, 'NotifyINFOBody', msg, opts)
end

--- Display a warning-level notification with optional custom highlights
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.warn(msg, opts)
  return notify(vim.log.levels.WARN, 'NotifyWARNBody', msg, opts)
end

--- Display an error-level notification with optional custom highlights
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.error(msg, opts)
  return notify(vim.log.levels.ERROR, 'NotifyERRORBody', msg, opts)
end

--- Display a debug notification with vim.inspect output in a code block
--- @param ... any Values to inspect and display
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
  M.warn(msg, { title = 'Debug ' .. Conf.icons.tools.DEBUG, height_offset = -1 })
end

return M
