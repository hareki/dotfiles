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
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.schedule(function()
      for _, r in ipairs(regions) do
        vim.api.nvim_buf_set_extmark(buf, ns, 0, r[1], {
          end_col = r[2],
          hl_group = r[3],
        })
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
      vim.treesitter.start(vim.api.nvim_win_get_buf(win), 'markdown')
    end
  else
    ---@cast msg table
    msg, apply_highlight = normalize_message(msg, opts)
  end

  -- Allow callers to chain their own callback
  local user_on_open = opts.on_open
  local autocmd_id = nil

  local function merged_on_open(win)
    local buf = vim.api.nvim_win_get_buf(win)

    if is_markdown then
      vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })
    end

    if apply_highlight then
      apply_highlight(win)

      -- Set up autocmd to reapply highlighting on various events that could affect highlights
      autocmd_id = vim.api.nvim_create_autocmd({
        'TextChanged',
        'TextChangedI', -- Content changes
        'ColorScheme', -- Theme/colorscheme changes
        'BufEnter',
        'WinEnter', -- Window/buffer focus changes
        'FileType', -- Filetype detection changes
      }, {
        buffer = buf,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            apply_highlight(win)
          end
        end,
        desc = 'Reapply Notifier Highlighting on Content or Display Changes',
      })
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
  end

  local ret = vim[opts.once and 'notify_once' or 'notify'](msg, opts.level, {
    replace = opts.id and notif_ids[opts.id] or nil,
    title = opts.title or 'Notifier',
    on_open = merged_on_open,
    on_close = on_close,
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

---@param title string
function M.debug(title, ...)
  local msg = ''
  if select('#', ...) > 0 then
    local obj = select('#', ...) == 1 and ... or { ... }
    msg = msg .. '```lua\n' .. vim.inspect(obj) .. '\n```'
  end
  M.notify(msg, { title = title, height_offset = -1 })
end

return M
