local filter = vim.tbl_filter
local uv = vim.uv

local extend_without_duplicates = function(l0, l1)
  local result = {}
  for _, v in ipairs(l0) do
    table.insert(result, v)
  end
  for _, v in ipairs(l1) do
    if not vim.tbl_contains(result, v) then
      table.insert(result, v)
    end
  end
  return result
end

local apply_cwd_only_aliases = function(opts)
  local has_cwd_only = opts.cwd_only ~= nil
  local has_only_cwd = opts.only_cwd ~= nil

  if has_only_cwd and not has_cwd_only then
    opts.cwd_only = opts.only_cwd
    opts.only_cwd = nil
  end

  return opts
end

local get_all_scope_buffers = function()
  local scope_core = require('scope.core')
  local scope_buffs = {}
  for _, bufs in pairs(scope_core.cache) do
    for _, buf in pairs(bufs) do
      table.insert(scope_buffs, buf)
    end
  end
  return scope_buffs
end

local find_buffer_tabpage = function(bufnr)
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

---@class ScopePickerScopeOpts
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

---@param user_opts? ScopePickerScopeOpts
---@return table|nil
return function(user_opts)
  local scope_core = require('scope.core')
  local picker_sources = require('snacks.picker.config.sources')
  local base_cfg = picker_sources.buffers or {}
  local opts = apply_cwd_only_aliases(vim.deepcopy(user_opts or {}))
  local buffer_format = require('plugins.ui.snacks.utils').buffer_format
  local picker_util = Snacks.picker.util
  local picker_actions = Snacks.picker.actions

  scope_core.revalidate()

  local show_all_buffers = opts.show_all_buffers
  if show_all_buffers == nil then
    show_all_buffers = true
  end
  local ignore_current_buffer = opts.ignore_current_buffer == true
  local cwd_only = opts.cwd_only == true
  local cwd_filter = opts.cwd
  local sort_mru = opts.sort_mru == true
  local sort_lastused = opts.sort_lastused
  if sort_lastused == nil then
    sort_lastused = base_cfg.sort_lastused
  end
  if sort_lastused == nil then
    sort_lastused = true
  end

  opts.show_all_buffers = nil
  opts.ignore_current_buffer = nil
  opts.sort_mru = nil
  opts.sort_lastused = nil
  opts.cwd_only = nil
  opts.only_cwd = nil

  local cwd = cwd_only and (uv and uv.cwd and uv.cwd()) or cwd_filter

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
        return vim.fn.buflisted(b) == 1
      end, vim.api.nvim_list_bufs()),
      get_all_scope_buffers()
    )
  )

  if vim.tbl_isempty(bufnrs) then
    return
  end

  if sort_mru then
    table.sort(bufnrs, function(a, b)
      return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
    end)
  end

  local buffers = {}
  local default_selection_idx = 1
  for _, bufnr in ipairs(bufnrs) do
    local flag = bufnr == vim.fn.bufnr('') and '%' or (bufnr == vim.fn.bufnr('#') and '#' or ' ')
    local info = vim.fn.getbufinfo(bufnr)[1]
    local tabpage = find_buffer_tabpage(bufnr)

    if sort_lastused and not ignore_current_buffer and flag == '#' then
      default_selection_idx = 2
    end

    local element = {
      bufnr = bufnr,
      flag = flag,
      info = info,
      tabpage = tabpage,
    }

    if sort_lastused and (flag == '#' or flag == '%') then
      local idx = ((buffers[1] ~= nil and buffers[1].flag == '%') and 2 or 1)
      table.insert(buffers, idx, element)
    else
      table.insert(buffers, element)
    end
  end

  local items = {}
  local current_buf = vim.api.nvim_get_current_buf()
  local alternate_buf = vim.fn.bufnr('#')

  for idx, buf in ipairs(buffers) do
    local bufnr = buf.bufnr
    local info = buf.info
    local mark = vim.api.nvim_buf_get_mark(bufnr, '"')
    if not mark or mark[1] == 0 then
      mark = { info.lnum, 0 }
    end
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      name = '[Scratch]'
    end

    local flags = table.concat({
      buf.flag,
      info.hidden == 1 and 'h' or (#(info.windows or {}) > 0 and 'a' or ''),
      vim.bo[bufnr].readonly and '=' or '',
      info.changed == 1 and '+' or '',
    })

    local item = {
      idx = idx,
      buf = bufnr,
      bufnr = bufnr,
      name = name,
      file = name,
      buftype = vim.bo[bufnr].buftype,
      filetype = vim.bo[bufnr].filetype,
      info = info,
      pos = mark,
      flags = flags,
      scope_tabpage = buf.tabpage,
      current = bufnr == current_buf,
      alternate = bufnr == alternate_buf,
    }

    item.text = picker_util.text(item, { 'buf', 'name', 'filetype', 'buftype' })
    items[#items + 1] = item
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

  local picker_opts = vim.tbl_deep_extend('force', {}, base_cfg, opts)
  picker_opts.source = picker_opts.source or 'scope_buffers'
  picker_opts.finder = nil
  picker_opts.hidden = nil
  picker_opts.unloaded = nil
  picker_opts.current = nil
  picker_opts.nofile = nil
  picker_opts.modified = nil
  picker_opts.sort_lastused = nil
  picker_opts.items = items
  picker_opts.title = picker_opts.title or 'Scope Buffers'
  picker_opts.format = buffer_format
  picker_opts.preview = picker_opts.preview or 'file'

  picker_opts.actions = picker_opts.actions or {}
  picker_opts.actions.scope_select_window = select_window

  if picker_opts.confirm == nil then
    picker_opts.confirm = scope_confirm
  end

  picker_opts.win = picker_opts.win or {}
  picker_opts.win.input = picker_opts.win.input or {}
  picker_opts.win.list = picker_opts.win.list or {}

  picker_opts.win.input.keys = vim.tbl_extend('force', picker_opts.win.input.keys or {}, {
    ['<C-w>'] = {
      'scope_select_window',
      mode = { 'n', 'i' },
      desc = 'Open buffer in current window',
    },
  })
  picker_opts.win.list.keys = vim.tbl_extend('force', picker_opts.win.list.keys or {}, {
    ['<C-w>'] = {
      'scope_select_window',
      mode = { 'n', 'i' },
      desc = 'Open buffer in current window',
    },
  })

  local existing_on_show = picker_opts.on_show
  picker_opts.on_show = function(picker)
    if existing_on_show then
      pcall(existing_on_show, picker)
    end
    if default_selection_idx and default_selection_idx > 1 then
      picker.list:view(default_selection_idx)
      picker_actions.list_scroll_center(picker)
    end
  end

  return Snacks.picker(picker_opts)
end
