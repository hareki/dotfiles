local filter = vim.tbl_filter
local uv = vim.uv

local function extend_without_duplicates(l0, l1)
  local result = {}
  for _, v in ipairs(l0) do
    table.insert(result, v)
  end
  for _, v in ipairs(l1) do
    if not vim.list_contains(result, v) then
      table.insert(result, v)
    end
  end
  return result
end

local function apply_cwd_only_aliases(opts)
  local has_cwd_only = opts.cwd_only ~= nil
  local has_only_cwd = opts.only_cwd ~= nil

  if has_only_cwd and not has_cwd_only then
    opts.cwd_only = opts.only_cwd
    opts.only_cwd = nil
  end

  return opts
end

local function get_all_scope_buffers()
  local scope_core = require('scope.core')
  local scope_buffs = {}
  for _, bufs in pairs(scope_core.cache) do
    for _, buf in pairs(bufs) do
      table.insert(scope_buffs, buf)
    end
  end
  return scope_buffs
end

local function find_buffer_tabpage(bufnr)
  local scope_core = require('scope.core')
  for tabpage, bufs in pairs(scope_core.cache) do
    for _, b in pairs(bufs) do
      if b == bufnr then
        return tabpage
      end
    end
  end
  return nil
end

---@class plugins.ui.snacks.pickers.scope.Opts
---@field show_all_buffers? boolean Show all buffers including unloaded ones (default: true)
---@field ignore_current_buffer? boolean Exclude the current buffer from results (default: false)
---@field cwd_only? boolean Filter buffers to only those in the current working directory (default: false)
---@field only_cwd? boolean Alias for cwd_only (deprecated, use cwd_only instead)
---@field cwd? string Filter buffers by a specific directory path
---@field sort_mru? boolean Sort buffers by most recently used (default: false)
---@field sort_lastused? boolean Sort with current/alternate buffer at top (default: true)
---@field title? string Picker window title
---@field preview? string|boolean Preview mode for the picker
---@field confirm? function Custom confirm action handler
---@field actions? table<string, function> Additional picker actions
---@field win? table Window configuration options
---@field on_show? function Callback when picker is shown

---@param user_opts? plugins.ui.snacks.pickers.scope.Opts
---@return table|nil
return function(user_opts)
  local scope_core = require('scope.core')
  local opts = apply_cwd_only_aliases(user_opts or {})
  local buffer_format = require('plugins.ui.snacks.utils').buffer_format
  local picker_actions = Snacks.picker.actions

  scope_core.revalidate()

  -- Extract scope-specific options with defaults
  local show_all_buffers = opts.show_all_buffers
  if show_all_buffers == nil then
    show_all_buffers = true
  end
  local ignore_current_buffer = opts.ignore_current_buffer == true
  local cwd_only = opts.cwd_only == true
  local cwd_filter = opts.cwd

  -- Compute cwd for filtering if needed
  local cwd = cwd_only and (uv and uv.cwd and uv.cwd()) or cwd_filter

  -- Get filtered buffer numbers from scope
  local bufnrs = filter(
    function(b)
      if not show_all_buffers and not vim.api.nvim_buf_is_loaded(b) then
        return false
      end
      if ignore_current_buffer and b == vim.api.nvim_get_current_buf() then
        return false
      end
      local name = vim.api.nvim_buf_get_name(b)
      if cwd_only then
        if name == '' then
          return false
        end
        return cwd and name:find(cwd, 1, true) ~= nil
      end
      if cwd and cwd ~= '' then
        if name == '' then
          return false
        end
        return name:find(cwd, 1, true) ~= nil
      end
      return true
    end,
    extend_without_duplicates(
      vim.tbl_filter(function(b)
        return vim.bo[b].buflisted
      end, vim.api.nvim_list_bufs()),
      get_all_scope_buffers()
    )
  )

  if vim.tbl_isempty(bufnrs) then
    return
  end

  -- Build items from buffer numbers
  local items = {}
  local current_buf = vim.api.nvim_get_current_buf()
  local alternate_buf = vim.fn.bufnr('#')

  for _, bufnr in ipairs(bufnrs) do
    local info = vim.fn.getbufinfo(bufnr)[1]
    local mark = vim.api.nvim_buf_get_mark(bufnr, '"')
    if not mark or mark[1] == 0 then
      mark = { info.lnum, 0 }
    end
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      name = '[Scratch]'
    end

    items[#items + 1] = {
      buf = bufnr,
      bufnr = bufnr,
      name = name,
      file = name,
      buftype = vim.bo[bufnr].buftype,
      filetype = vim.bo[bufnr].filetype,
      info = info,
      pos = mark,
      scope_tabpage = find_buffer_tabpage(bufnr),
      current = bufnr == current_buf,
      alternate = bufnr == alternate_buf,
    }
  end

  local function scope_confirm(picker, _, action)
    local selection = picker:selected({ fallback = true })
    local primary = selection[1]

    if not primary or not primary.buf or not vim.api.nvim_buf_is_valid(primary.buf) then
      return
    end

    picker:norm(function()
      picker_actions.jump(picker, primary, action)
      local tabpage = primary.scope_tabpage or find_buffer_tabpage(primary.buf)
      if tabpage and vim.api.nvim_tabpage_is_valid(tabpage) then
        local target_buf = primary.buf
        vim.schedule(function()
          if vim.api.nvim_tabpage_is_valid(tabpage) and vim.api.nvim_buf_is_valid(target_buf) then
            vim.api.nvim_set_current_tabpage(tabpage)
            vim.api.nvim_set_current_buf(target_buf)
          end
        end)
      end
    end)
  end

  local function select_window(picker)
    local selection = picker:selected({ fallback = true })
    local primary = selection[1]
    if not primary or not primary.buf or not vim.api.nvim_buf_is_valid(primary.buf) then
      return
    end
    picker:norm(function()
      picker:close()
      local target_buf = primary.buf
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(target_buf) then
          vim.api.nvim_set_current_buf(target_buf)
        end
      end)
    end)
  end

  -- Merge user opts with scope-specific overrides
  local picker_opts = vim.tbl_deep_extend('force', {}, opts, {
    source = 'scope_buffers',
    title = opts.title or 'Scope Buffers',
    items = items,
    finder = nil,
    format = buffer_format,
    preview = opts.preview or 'file',
    confirm = opts.confirm or scope_confirm,

    actions = vim.tbl_extend('force', opts.actions or {}, {
      scope_select_window = select_window,
    }),

    win = {
      input = {
        keys = vim.tbl_extend(
          'force',
          (opts.win and opts.win.input and opts.win.input.keys) or {},
          {
            ['<C-w>'] = {
              'scope_select_window',
              mode = { 'n', 'i' },
              desc = 'Open Buffer in Current Window',
            },
          }
        ),
      },
      list = {
        keys = vim.tbl_extend('force', (opts.win and opts.win.list and opts.win.list.keys) or {}, {
          ['<C-w>'] = {
            'scope_select_window',
            mode = { 'n', 'i' },
            desc = 'Open Buffer in Current Window',
          },
        }),
      },
    },
  })

  -- Clean up scope-specific options that shouldn't be passed to Snacks
  picker_opts.show_all_buffers = nil
  picker_opts.ignore_current_buffer = nil
  picker_opts.cwd_only = nil
  picker_opts.only_cwd = nil
  picker_opts.cwd = nil

  return Snacks.picker(picker_opts)
end
