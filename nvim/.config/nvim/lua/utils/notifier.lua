-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua

--- @class utils.notifier
local M = {}

--- @alias utils.notifier.NotifierOpts { title?: string, height_offset?: integer }

--- @alias utils.notifier.MessageChunk { [1]: string, [2]: string } Text and its highlight group
--- @alias utils.notifier.Message string | utils.notifier.MessageChunk[]

local highlight_ns = vim.api.nvim_create_namespace('trouble_notify_hl')

--- Flatten a chunk list and build an on_open that restores highlights.
--- @param chunks utils.notifier.MessageChunk[]
--- @return string plain     flattened text for vim.notify
--- @return function on_open callback that reapplies extmarks
local function normalize_message(chunks)
  local parts, regions = {}, {}
  local line, col = 0, 0

  for _, chunk in ipairs(chunks) do
    local text, group = chunk[1], chunk[2]
    table.insert(parts, text)

    local lines = vim.split(text, '\n', { plain = true })
    for i, line_text in ipairs(lines) do
      -- The first part continues the current line, the others start a new one
      if i > 1 then
        line, col = line + 1, 0
      end
      regions[#regions + 1] = { line, col, col + #line_text, group }
      col = col + #line_text
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
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
local function notify(level, msg, opts)
  opts = opts or {}

  local apply_highlight
  if type(msg) == 'string' then
    -- Strings: fall back to Treesitter markdown
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
    msg, apply_highlight = normalize_message(msg)
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
  return notify(vim.log.levels.INFO, msg, opts)
end

--- Display a warning-level notification with optional custom highlights
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.warn(msg, opts)
  return notify(vim.log.levels.WARN, msg, opts)
end

--- Display an error-level notification with optional custom highlights
--- @param msg utils.notifier.Message
--- @param opts? utils.notifier.NotifierOpts
--- @return any handle The notification record
function M.error(msg, opts)
  return notify(vim.log.levels.ERROR, msg, opts)
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
