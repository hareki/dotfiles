local tab_utils = require('utils.tab')
local snacks_utils = require('plugins.ui.snacks.utils')
local notifier = require('utils.notifier')

local function unique_insert(list, value)
  if value == nil then
    return false
  end
  if not vim.tbl_contains(list, value) then
    table.insert(list, value)
    return true
  end
  return false
end

local function append_buffer_metadata(win, buffer_ids, file_names, file_paths)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end

  if not unique_insert(buffer_ids, buf) then
    return
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    table.insert(file_names, '[No Name]')
    return
  end

  table.insert(file_names, vim.fn.fnamemodify(name, ':t'))
  table.insert(file_paths, name)
end

local function build_tab_items()
  local tabs = vim.api.nvim_list_tabpages()
  if vim.tbl_isempty(tabs) then
    return {}, 1
  end

  local items = {}
  local current_tab = vim.api.nvim_get_current_tabpage()
  local default_idx = 1

  for idx, tab in ipairs(tabs) do
    local wins = vim.api.nvim_tabpage_list_wins(tab)
    local buffer_ids = {}
    local file_names = {}
    local file_paths = {}

    for _, win in ipairs(wins) do
      append_buffer_metadata(win, buffer_ids, file_names, file_paths)
    end

    local first_buf = buffer_ids[1]
    local first_path = first_buf and vim.api.nvim_buf_get_name(first_buf) or nil
    if first_path == '' then
      first_path = nil
    end
    local focus_win = vim.api.nvim_tabpage_get_win(tab)
    local display_name = tab_utils.get_tab_name(tab, buffer_ids)
    local is_current = tab == current_tab
    if is_current then
      display_name = display_name .. ' '
      default_idx = idx
    end

    local ordinal_parts = { display_name }
    if #file_names > 0 then
      ordinal_parts[#ordinal_parts + 1] = table.concat(file_names, ' ')
    end
    if #file_paths > 0 then
      ordinal_parts[#ordinal_parts + 1] = table.concat(file_paths, ' ')
    end

    local ordinal = table.concat(ordinal_parts, ' ')
    items[#items + 1] = {
      idx = idx,
      tabpage = tab,
      tabnr = vim.api.nvim_tabpage_get_number(tab),
      buffer_ids = buffer_ids,
      file_names = file_names,
      file_paths = file_paths,
      is_current = is_current,
      icon = '',
      display = display_name,
      text = ordinal,
      ordinal = ordinal,
      file = first_path,
      buf = first_buf,
      win = focus_win,
    }
  end

  return items, default_idx
end

return function(user_opts)
  local picker_sources = require('snacks.picker.config.sources')
  local base_cfg = picker_sources.tabs or {}

  local default_user_opts = {
    keys = {
      close_tab_i = '<C-d>',
      close_tab_n = 'x',
    },
    show_preview = true,
  }

  local opts = vim.tbl_deep_extend('force', {}, default_user_opts, user_opts or {})

  if type(opts.keys) ~= 'table' then
    opts.keys = {}
  end

  local keys_cfg = opts.keys
  local close_i = keys_cfg.close_tab_i
  local close_n = keys_cfg.close_tab_n
  local show_preview = opts.show_preview

  if opts.keys then
    opts.keys.close_tab_i = nil
    opts.keys.close_tab_n = nil
    if vim.tbl_isempty(opts.keys) then
      opts.keys = nil
    end
  end
  opts.show_preview = nil

  local items, default_selection_idx = build_tab_items()
  if vim.tbl_isempty(items) then
    return
  end

  local picker_actions = Snacks.picker.actions
  local picker_opts = vim.tbl_deep_extend('force', {}, base_cfg, opts)
  picker_opts.items = items
  picker_opts.source = picker_opts.source or 'tabs'
  picker_opts.title = picker_opts.title or 'Tabs'
  picker_opts.finder = nil

  local function build_toggleterm_lookup()
    local ok, toggleterm = pcall(require, 'toggleterm.terminal')
    if not ok then
      return {}
    end

    local lookup = {}
    local ok_terms, terms = pcall(toggleterm.get_all, true)
    if not ok_terms then
      return lookup
    end

    for _, term in ipairs(terms) do
      if type(term) == 'table' and term.bufnr then
        lookup[term.bufnr] = term
      end
    end

    return lookup
  end

  local function make_preview_items(tab_item)
    if not tab_item then
      return {}
    end

    local toggleterm_lookup = build_toggleterm_lookup()
    local current_buf = vim.api.nvim_get_current_buf()
    local alternate_buf = vim.fn.bufnr('#')
    local seen = {}
    local bufnrs = {}

    local function add_buf(bufnr)
      if bufnr == nil or seen[bufnr] then
        return
      end

      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local buftype = vim.bo[bufnr].buftype or ''
      if buftype ~= '' and buftype ~= 'terminal' then
        return
      end
      seen[bufnr] = true
      bufnrs[#bufnrs + 1] = bufnr
    end

    for _, bufnr in ipairs(tab_item.buffer_ids or {}) do
      add_buf(bufnr)
    end

    if tab_item.tabpage and vim.api.nvim_tabpage_is_valid(tab_item.tabpage) then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab_item.tabpage)) do
        add_buf(vim.api.nvim_win_get_buf(win))
      end
    end

    local ok_scope, scope_core = pcall(require, 'scope.core')
    if ok_scope then
      pcall(scope_core.revalidate)
      local scoped = scope_core.cache and scope_core.cache[tab_item.tabpage]
      if scoped then
        for _, bufnr in ipairs(scoped) do
          add_buf(bufnr)
        end
      end
    end

    if vim.tbl_isempty(bufnrs) then
      return {}
    end

    table.sort(bufnrs, function(a, b)
      local info_a = vim.fn.getbufinfo(a)[1]
      local info_b = vim.fn.getbufinfo(b)[1]
      local last_a = info_a and info_a.lastused or 0
      local last_b = info_b and info_b.lastused or 0
      return last_a > last_b
    end)

    local result = {}
    for _, bufnr in ipairs(bufnrs) do
      local buftype = vim.bo[bufnr].buftype or ''
      local name = vim.api.nvim_buf_get_name(bufnr)
      local display_name
      local file = name

      if buftype == '' then
        if name == '' then
          display_name = '[No Name]'
          file = display_name
        else
          display_name = vim.fn.fnamemodify(name, ':t')
        end
      else
        local term = toggleterm_lookup[bufnr]
        local term_name = term and term.display_name

        if term_name == nil or term_name == '' then
          term_name = term and term.id and tostring(term.id) or nil
        end

        if not term_name then
          local ok_toggle_number, toggle_number =
            pcall(vim.api.nvim_buf_get_var, bufnr, 'toggle_number')
          if ok_toggle_number and toggle_number ~= nil then
            term_name = tostring(toggle_number)
          end
        end

        term_name = term_name or tostring(bufnr)
        display_name = term_name
        file = term_name
      end

      local entry = {
        bufnr = bufnr,
        buf = buftype == '' and bufnr or nil,
        name = display_name,
        file = file,
        buftype = buftype,
        filetype = vim.bo[bufnr].filetype or '',
        current = bufnr == current_buf,
        alternate = bufnr == alternate_buf,
      }

      result[#result + 1] = entry
    end

    return result
  end

  local function preview_tab_buffers(ctx)
    if not ctx.item then
      ctx.preview:reset()
      return
    end

    ctx.preview:reset()
    ctx.preview:set_title(string.format('Tab %d Buffers', ctx.item.tabnr or 0))
    -- ctx.preview:minimal()
    ctx.preview:wo({
      number = true,
    })

    local items_for_preview = make_preview_items(ctx.item)
    if vim.tbl_isempty(items_for_preview) then
      ctx.preview:notify('No file or terminal buffers', 'info', { item = false })
      return
    end

    local highlight = Snacks.picker.highlight
    local width = 0
    if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
      width = vim.api.nvim_win_get_width(ctx.win)
    elseif
      ctx.preview.win
      and ctx.preview.win.win
      and vim.api.nvim_win_is_valid(ctx.preview.win.win)
    then
      width = vim.api.nvim_win_get_width(ctx.preview.win.win)
    end
    if width <= 0 then
      width = vim.o.columns
    end
    width = math.max(width, 1)

    local lines = {}
    local extmarks = {}
    local ns = ctx.preview:ns()

    for idx, buffer_item in ipairs(items_for_preview) do
      local spec = snacks_utils.buffer_format(buffer_item, ctx.picker)
      spec = highlight.resolve(spec, width)
      local text, marks = highlight.to_text(spec)
      lines[idx] = text

      for _, mark in ipairs(marks) do
        if type(mark) == 'table' and mark.col then
          extmarks[#extmarks + 1] = { row = idx - 1, mark = mark }
        end
      end
    end

    ctx.preview:set_lines(lines)
    vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)

    for _, ext in ipairs(extmarks) do
      local mark = vim.deepcopy(ext.mark)
      local col = mark.col or 0
      mark.col = nil
      mark.row = nil
      mark.field = nil
      pcall(vim.api.nvim_buf_set_extmark, ctx.buf, ns, ext.row, col, mark)
    end
  end

  picker_opts.preview = show_preview and preview_tab_buffers or false

  local function focus_tab(tabpage, win)
    if not vim.api.nvim_tabpage_is_valid(tabpage) then
      return
    end
    vim.api.nvim_set_current_tabpage(tabpage)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    else
      local target_win = vim.api.nvim_tabpage_get_win(tabpage)
      if target_win and vim.api.nvim_win_is_valid(target_win) then
        vim.api.nvim_set_current_win(target_win)
      end
    end
  end

  local function tabs_confirm(picker)
    local selection = picker:selected({ fallback = true })
    local primary = selection[1]
    if not primary or not primary.tabpage then
      return
    end
    picker:norm(function()
      picker:close()
      focus_tab(primary.tabpage, primary.win)
    end)
  end

  local function rebuild_items()
    local refreshed, idx = build_tab_items()
    if vim.tbl_isempty(refreshed) then
      return nil, 1
    end
    picker_opts.items = refreshed
    default_selection_idx = idx
    return refreshed, idx
  end

  local function close_tab(picker)
    local selection = picker:selected({ fallback = true })
    if not selection or selection[1] == nil then
      return
    end

    picker:norm(function()
      local tabnrs = {}
      for _, item in ipairs(selection) do
        if item.tabpage and vim.api.nvim_tabpage_is_valid(item.tabpage) then
          tabnrs[#tabnrs + 1] = vim.api.nvim_tabpage_get_number(item.tabpage)
        end
      end
      table.sort(tabnrs, function(a, b)
        return a > b
      end)
      if #tabnrs == 1 then
        notifier.error('Cannot close last tab page')
        return
      end

      for _, tabnr in ipairs(tabnrs) do
        vim.cmd(string.format('%dtabclose', tabnr))
      end
    end)

    local refreshed = rebuild_items()
    if not refreshed then
      picker:close()
      return
    end

    picker.opts.items = picker_opts.items
    picker.list:set_target(default_selection_idx, nil, { force = true })
    picker:refresh()
    vim.schedule(function()
      if not picker.closed then
        picker.list:view(default_selection_idx, nil, true)
      end
    end)
  end

  picker_opts.actions = picker_opts.actions or {}
  picker_opts.actions.close_tab = close_tab
  picker_opts.confirm = picker_opts.confirm or tabs_confirm

  picker_opts.format = function(item)
    local icon = item.icon or ''
    return {
      { icon .. ' ', 'Macro' },
      { item.display, 'SnacksPickerFile' },
    }
  end

  picker_opts.win = picker_opts.win or {}
  picker_opts.win.input = picker_opts.win.input or {}
  picker_opts.win.list = picker_opts.win.list or {}
  picker_opts.win.input.keys = picker_opts.win.input.keys or {}
  picker_opts.win.list.keys = picker_opts.win.list.keys or {}

  if close_i and close_i ~= '' then
    picker_opts.win.input.keys[close_i] = {
      'close_tab',
      mode = { 'i' },
      desc = 'Close Tab',
    }
    picker_opts.win.list.keys[close_i] = {
      'close_tab',
      mode = { 'i' },
      desc = 'Close Tab',
    }
  end

  if close_n and close_n ~= '' then
    picker_opts.win.input.keys[close_n] = {
      'close_tab',
      mode = { 'n' },
      desc = 'Close Tab',
    }
    picker_opts.win.list.keys[close_n] = {
      'close_tab',
      mode = { 'n' },
      desc = 'Close Tab',
    }
  end

  local existing_on_show = picker_opts.on_show
  picker_opts.on_show = function(picker)
    if existing_on_show then
      pcall(existing_on_show, picker)
    end
    if default_selection_idx and default_selection_idx > 0 then
      picker.list:view(default_selection_idx)
      picker_actions.list_scroll_center(picker)
    end
  end

  return Snacks.picker(picker_opts)
end
