---@class utils.notify
---@brief [[
--- A tiny wrapper around nvim-notify that supports
--- per-chunk highlighting with the familiar `{text, hl}` tuples
--- used by |vim.api.nvim_echo()|.
---@brief ]]
local M = {}

--- Produce a plain message and an `on_open` callback that re-adds
--- the per-chunk highlights.
---
--- @param chunks  string|table
---        an array of strings or tuples where each tuple is `{text, hl_group}`.
--- @param opts    table?
---        • `default_hl`  string: fallback highlight (defaults to `'Normal'`)
---        • `ns`          string:  namespace name (defaults to `'notify_hl'`)
--- @return string plain_message  Flattened text
--- @return function|nil on_open Callback that restores highlights
local function normalize_message(chunks, opts)
  if type(chunks) == 'string' then
    return chunks, nil
  end

  opts = opts or {}
  local default_hl = opts.default_hl or 'Normal'
  local ns = vim.api.nvim_create_namespace(opts.ns or 'notify_hl')

  -- concatenate text while remembering its span
  local parts, regions, col = {}, {}, 0
  for _, item in ipairs(chunks) do
    local text = item[1] or item -- allow bare strings inside the list
    local group = item[2] or default_hl
    table.insert(parts, text)
    regions[#regions + 1] = { col, col + #text, group }
    col = col + #text
  end
  local plain_message = table.concat(parts)

  ---Restore highlight extmarks once the floating window opens.
  ---@param win integer Window handle
  local function on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)
    for _, r in ipairs(regions) do
      vim.api.nvim_buf_add_highlight(buf, ns, r[3], 0, r[1], r[2])
    end
  end

  return plain_message, on_open
end

--- Low-level helper that all public wrappers delegate to.
---
--- @param level       integer  Value from |vim.log.levels|
--- @param default_hl  string   Notify<LEVEL>Body to use when chunks omit `hl`
--- @param fallback_title string Default title when `opts.title` is omitted
--- @param message     string|table
--- @param opts        table?   Passed straight through to |vim.notify()|
local function notify_level(level, default_hl, fallback_title, message, opts)
  opts = opts or {}
  opts.title = opts.title or fallback_title

  local plain_message, on_open_hl = normalize_message(message, { default_hl = default_hl })
  if on_open_hl then
    -- Compose callbacks if caller already supplied one
    opts.on_open = opts.on_open
        and function(win)
          on_open_hl(win)
          opts.on_open(win)
        end
      or on_open_hl
  end
  vim.notify(plain_message, level, opts)
end

--- @param message string|table
--- @param opts? table Same as |vim.notify()|
function M.info(message, opts)
  notify_level(vim.log.levels.INFO, 'NotifyINFOBody', 'Info', message, opts)
end

--- @param message string|table
--- @param opts? table Same as |vim.notify()|
function M.warn(message, opts)
  notify_level(vim.log.levels.WARN, 'NotifyWARNBody', 'Warn', message, opts)
end

--- @param message string|table
--- @param opts? table Same as |vim.notify()|
function M.error(message, opts)
  notify_level(vim.log.levels.ERROR, 'NotifyERRORBody', 'Error', message, opts)
end

return M
