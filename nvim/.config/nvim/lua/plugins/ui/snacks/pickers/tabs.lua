local tab_utils = require('utils.tab')

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
  local opts = vim.deepcopy(user_opts or {})

  local keys_cfg = opts.keys or {}
  local close_i = keys_cfg.close_tab_i or '<C-d>'
  local close_n = keys_cfg.close_tab_n or 'x'
  local show_preview = opts.show_preview
  if show_preview == nil then
    show_preview = true
  end

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
  picker_opts.preview = show_preview and 'file' or false
  picker_opts.finder = nil

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
