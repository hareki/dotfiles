---@class utils.hl-at-cursor
local M = {}

--- Show all highlight groups affecting the cursor (Markdown popup)
function M.show()
  local bufnr = 0
  local pos = vim.api.nvim_win_get_cursor(0)
  local row0, col0 = pos[1] - 1, pos[2]
  local origin_win = vim.api.nvim_get_current_win()
  local origin_buf = vim.api.nvim_win_get_buf(origin_win)

  -- 1) Vimscript syntax stack
  local syntax_groups = {}
  for _, id in ipairs(vim.fn.synstack(row0 + 1, col0 + 1)) do
    local trans = vim.fn.synIDtrans(id)
    local name = vim.fn.synIDattr(trans, 'name')
    if name and name ~= '' then
      table.insert(syntax_groups, name)
    end
  end

  -- 2) Tree-sitter captures -> resolved highlight group
  local function resolve_link(name)
    local seen, last = {}, name
    while name and not seen[name] do
      seen[name] = true
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = true })
      if not ok or not hl then
        break
      end
      if hl.link and hl.link ~= '' then
        last, name = hl.link, hl.link
      else
        break
      end
    end
    return last
  end

  local ts_pairs = {}
  if vim.treesitter and vim.treesitter.get_captures_at_pos then
    local ok, caps = pcall(vim.treesitter.get_captures_at_pos, bufnr, row0, col0)
    if ok and type(caps) == 'table' then
      for _, c in ipairs(caps) do
        local cap = c.capture or c
        if type(cap) == 'string' then
          table.insert(ts_pairs, { cap, resolve_link(cap) or cap })
        end
      end
    end
  end

  -- 3) Extmarks with hl_group covering the cursor
  local function cursor_in_range(srow, scol, d)
    local erow = d.end_row or srow
    local ecol = d.end_col or (d.hl_eol and math.huge or scol)
    if row0 > srow or (row0 == srow and col0 >= scol) then
      if row0 < erow or (row0 == erow and col0 < ecol) or (d.hl_eol and row0 == srow) then
        return true
      end
    end
    return false
  end

  local extmark_entries = {}
  for ns_name, ns_id in pairs(vim.api.nvim_get_namespaces()) do
    local marks = vim.api.nvim_buf_get_extmarks(
      bufnr,
      ns_id,
      { row0, 0 },
      { row0, -1 },
      { details = true }
    )
    for _, m in ipairs(marks) do
      local _, srow, scol, d = m[1], m[2], m[3], m[4]
      if d and d.hl_group and cursor_in_range(srow, scol, d) then
        table.insert(
          extmark_entries,
          string.format('%s (ns:%s prio:%s)', d.hl_group, ns_name, d.priority or 0)
        )
      end
    end
  end

  -- 4) Window matches
  local match_groups = {}
  for _, mm in ipairs(vim.fn.getmatches()) do
    if mm.group and mm.group ~= '' then
      table.insert(match_groups, mm.group)
    end
  end

  -- Dedupe
  local function uniq(list)
    local seen, out = {}, {}
    for _, v in ipairs(list) do
      if not seen[v] then
        seen[v] = true
        table.insert(out, v)
      end
    end
    return out
  end

  local function uniq_ts(entries)
    local seen, out = {}, {}
    for _, e in ipairs(entries) do
      local key = (e[1] or '') .. '→' .. (e[2] or '')
      if not seen[key] then
        seen[key] = true
        table.insert(out, e)
      end
    end
    return out
  end

  -- Build Markdown lines
  local lines = {}

  local function emit_section(title, items, kind)
    table.insert(lines, '**' .. title .. '**')
    if kind == 'ts' then
      local list = uniq_ts(items)
      if #list == 0 then
        table.insert(lines, 'none')
      else
        for _, e in ipairs(list) do
          table.insert(lines, string.format('- `@%s` → `%s`', e[1], e[2]))
        end
      end
    else
      local list = uniq(items)
      if #list == 0 then
        table.insert(lines, 'none')
      else
        for _, item in ipairs(list) do
          local name, rest = item:match('^([^%s]+)%s*(.*)$')
          if name then
            table.insert(
              lines,
              string.format('- `%s`%s', name, (#rest > 0) and (' ' .. rest) or '')
            )
          else
            table.insert(lines, '- ' .. item)
          end
        end
      end
    end
    -- table.insert(lines, '') -- blank line between sections
  end

  emit_section('1. Syntax', syntax_groups)
  emit_section('2. Tree-sitter', ts_pairs, 'ts')
  emit_section('3. Extmarks', extmark_entries)
  emit_section('4. Matches', match_groups)

  -- Popup (create buffer first)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].modifiable = false
  vim.bo[buf].syntax = 'off' -- avoid legacy syntax racing TS

  local maxw = 0
  for _, s in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(s)
    if w > maxw then
      maxw = w
    end
  end

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 1,
    width = math.max(28, maxw + 2),
    height = math.min(#lines, 30),
    style = 'minimal',
    border = 'rounded',
    title = string.format(' Highlights (%d, %d) ', row0 + 1, col0 + 1),
    title_pos = 'center',
  })

  vim.bo[buf].filetype = 'markdown'

  local closing = false
  local ignore_cursor_close = false
  local augroup

  local function with_cursor_ignore()
    ignore_cursor_close = true
    vim.defer_fn(function()
      ignore_cursor_close = false
    end, 20)
  end

  local function close_popup()
    if closing then
      return false
    end
    closing = true
    if augroup then
      pcall(vim.api.nvim_del_augroup_by_id, augroup)
      augroup = nil
    end
    pcall(vim.keymap.del, 'n', '<Tab>', { buffer = origin_buf })
    pcall(vim.keymap.del, 'n', '<Esc>', { buffer = origin_buf })
    pcall(vim.keymap.del, 'n', '<Tab>', { buffer = buf })
    local ok = true
    if vim.api.nvim_win_is_valid(win) then
      ok = pcall(vim.api.nvim_win_close, win, true)
    end
    closing = false
    return ok
  end

  local function focus_popup()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    with_cursor_ignore()
    vim.api.nvim_set_current_win(win)
  end

  local function focus_origin()
    if not vim.api.nvim_win_is_valid(origin_win) then
      close_popup()
      return
    end
    with_cursor_ignore()
    vim.api.nvim_set_current_win(origin_win)
  end

  local function origin_escape()
    with_cursor_ignore()
    close_popup()
    vim.schedule(function()
      local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
      vim.api.nvim_feedkeys(esc, 'n', false)
    end)
  end

  augroup = vim.api.nvim_create_augroup('HlAtCursorPopup' .. win, { clear = true })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = augroup,
    buffer = origin_buf,
    callback = function()
      if ignore_cursor_close then
        return
      end
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      if vim.api.nvim_get_current_win() ~= origin_win then
        return
      end
      close_popup()
    end,
  })

  vim.api.nvim_create_autocmd('WinEnter', {
    group = augroup,
    callback = function()
      local current = vim.api.nvim_get_current_win()
      if current == win or current == origin_win then
        return
      end
      close_popup()
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    callback = function(args)
      if args.buf == buf or args.buf == origin_buf then
        return
      end
      close_popup()
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(args)
      local target = tonumber(args.match)
      if target == win or target == origin_win then
        close_popup()
      end
    end,
  })

  vim.keymap.set('n', '<Tab>', focus_popup, {
    buffer = origin_buf,
    nowait = true,
    desc = 'Focus Highlight Popup',
  })

  vim.keymap.set('n', '<Esc>', origin_escape, {
    buffer = origin_buf,
    nowait = true,
    desc = 'Close Highlight Popup',
  })

  vim.keymap.set('n', '<Tab>', focus_origin, {
    buffer = buf,
    nowait = true,
    desc = 'Return Focus to Source Window',
  })

  vim.wo[win].conceallevel = 2
  vim.wo[win].wrap = false
  vim.wo[win].signcolumn = 'no'

  vim.keymap.set('n', 'q', close_popup, {
    buffer = buf,
    nowait = true,
    desc = 'Close Highlight Popup',
  })
  vim.keymap.set('n', '<Esc>', close_popup, {
    buffer = buf,
    nowait = true,
    desc = 'Close Highlight Popup',
  })
end

return M
