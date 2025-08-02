-- trouble.nvim notifier with supported custom highlight groups
-- https://github.com/folke/trouble.nvim/blob/main/lua/trouble/util.lua
local M = {}
---@alias NotifyOpts { level?: number, title?: string, once?: boolean, id?:string, on_open?: fun(), default_hl?: string }

---@alias MessageTuple {string, string?}
---@alias Message string|string[]|MessageTuple[]

---@type table<string, any>
local notif_ids = {}

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

  local parts, regions, col = {}, {}, 0
  for _, item in ipairs(chunks) do
    local text, group
    if type(item) == 'string' then -- bare string
      text, group = item, default_hl
    else -- {text, hl}
      text, group = item[1], item[2] or default_hl
    end
    table.insert(parts, text)
    regions[#regions + 1] = { col, col + #text, group } -- [start,stop,hl]
    col = col + #text
  end
  local plain = table.concat(parts)

  ---reapply the extmarks once the floating window opens
  ---@param win integer
  local function on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)
    apply_win_opts(win)
    for _, r in ipairs(regions) do
      vim.api.nvim_buf_add_highlight(buf, ns, r[3], 0, r[1], r[2])
    end
  end

  return plain, on_open
end

---@param msg  string|table
---@param opts table?
function M.notify(msg, opts)
  opts = opts or {}

  -- Prepare the message/handler depending on the input shape
  local on_open_cb
  if is_tuple_list(msg) then
    msg, on_open_cb = normalize_message(msg, opts)
  else
    -- strings / list-of-strings: fall back to Treesitter markdown
    msg = type(msg) == 'table' and table.concat(msg, '\n') or msg
    on_open_cb = function(win)
      apply_win_opts(win)
      vim.treesitter.start(vim.api.nvim_win_get_buf(win), 'markdown')
    end
  end

  -- Allow callers to chain their own callback
  local user_on_open = opts.on_open
  local function combined_open(win)
    if on_open_cb then
      on_open_cb(win)
    end
    if user_on_open then
      user_on_open(win)
    end
  end

  local ret = vim[opts.once and 'notify_once' or 'notify'](msg, opts.level, {
    replace = opts.id and notif_ids[opts.id] or nil,
    title = opts.title or 'Trouble',
    on_open = combined_open,
  })

  if opts.id then
    notif_ids[opts.id] = ret
  end
  return ret
end

---@param msg Message
---@param opts? NotifyOpts
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
---@param opts? NotifyOpts
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
---@param opts? NotifyOpts
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

---@param msg string
function M.debug(msg, ...)
  if select('#', ...) > 0 then
    local obj = select('#', ...) == 1 and ... or { ... }
    msg = msg .. '\n```lua\n' .. vim.inspect(obj) .. '\n```'
  end
  M.notify(msg, { title = 'Debug' })
end

return M
