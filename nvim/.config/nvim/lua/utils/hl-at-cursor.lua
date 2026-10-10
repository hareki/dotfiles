local common = require('utils.common')

--- @class utils.hl-at-cursor
local M = {}

-- Closer of the currently open popup, if any. Only one popup may exist at a
-- time: a second one would otherwise fight the first over the origin buffer's
-- <Tab>/<Esc> keymaps and orphan the earlier float
local close_active_popup

local function collect_matches()
  local groups = {}
  for _, mm in ipairs(vim.fn.getmatches()) do
    if mm.group and mm.group ~= '' then
      table.insert(groups, mm.group)
    end
  end
  return groups
end

--- Render markdown lines for the popup.
local function build_lines(syntax_groups, ts_pairs, extmark_entries, match_groups)
  local lines = {}

  local function emit(title, items, kind)
    table.insert(lines, '**' .. title .. '**')
    if kind == 'ts' then
      local list = vim.list.unique(items, function(e)
        return e[1] .. '\0' .. e[2]
      end)
      if #list == 0 then
        table.insert(lines, 'none')
      else
        for _, e in ipairs(list) do
          table.insert(lines, string.format('- `@%s` %s `%s`', e[1], Conf.icons.misc.ARROW, e[2]))
        end
      end
    else
      local list = vim.list.unique(items)
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
  end

  emit('1. Syntax', syntax_groups)
  emit('2. Tree-sitter', ts_pairs, 'ts')
  emit('3. Extmarks', extmark_entries)
  emit('4. Matches', match_groups)
  return lines
end

--- Create the floating buffer/window pair for the popup.
--- @return integer buf, integer win
local function open_popup(lines, row0, col0)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].modifiable = false

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
  -- avoid legacy syntax racing TS; must follow the ft change, whose cascade resets 'syntax'
  vim.bo[buf].syntax = 'off'
  vim.wo[win].conceallevel = 2
  vim.wo[win].wrap = false
  vim.wo[win].signcolumn = 'no'

  return buf, win
end

--- Wire popup lifecycle: keymaps, autocmds, focus toggling, cleanup.
local function attach_lifecycle(buf, win, origin_buf, origin_win)
  local closing = false
  local augroup
  -- Re-entering origin_win fires CursorMoved even though its cursor never moved
  local origin_pos = vim.api.nvim_win_get_cursor(origin_win)

  -- Assigned once the origin buffer's <Tab>/<Esc> overrides are set below
  --- @type fun()
  local release_origin_maps

  local function close_popup()
    if closing then
      return false
    end
    closing = true
    if close_active_popup == close_popup then
      close_active_popup = nil
    end
    if augroup then
      pcall(vim.api.nvim_del_augroup_by_id, augroup)
      augroup = nil
    end
    release_origin_maps()
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
    vim.api.nvim_set_current_win(win)
  end

  local function focus_origin()
    if not vim.api.nvim_win_is_valid(origin_win) then
      close_popup()
      return
    end
    vim.api.nvim_set_current_win(origin_win)
  end

  local function origin_escape()
    close_popup()
    vim.schedule(function()
      local esc = vim.keycode('<Esc>')
      -- 'm' (remap) so the global <Esc> mapping (Clear Highlight) runs; the popup's
      -- buffer-local <Esc> is already released by close_popup, so this cannot recurse
      vim.api.nvim_feedkeys(esc, 'm', false)
    end)
  end

  augroup = vim.api.nvim_create_augroup('utils.hl-at-cursor.popup-' .. win, { clear = true })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = augroup,
    buffer = origin_buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      if vim.api.nvim_get_current_win() ~= origin_win then
        return
      end
      if vim.deep_equal(vim.api.nvim_win_get_cursor(origin_win), origin_pos) then
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

  -- Overrides rather than plain maps: the origin buffer may have its own <Tab>/<Esc>
  -- (e.g. nvim-tree's <Tab> preview) for close_popup to hand back
  release_origin_maps = common.override_buf_keymaps(origin_buf, {
    { 'n', '<Tab>', focus_popup, { nowait = true, desc = 'Focus Highlight Popup' } },
    { 'n', '<Esc>', origin_escape, { nowait = true, desc = 'Close Highlight Popup' } },
  })

  vim.keymap.set('n', '<Tab>', focus_origin, {
    buffer = buf,
    nowait = true,
    desc = 'Return Focus to Source Window',
  })

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

  close_active_popup = close_popup
end

--- Show all highlight groups affecting the cursor position in a Markdown popup.
--- Displays syntax groups, Tree-sitter captures, extmarks, and window matches.
--- @return nil
function M.show()
  if close_active_popup then
    close_active_popup()
  end

  local origin_win = vim.api.nvim_get_current_win()
  local origin_buf = vim.api.nvim_win_get_buf(origin_win)
  -- The current buffer at the cursor, with every group resolved through its links
  local items = vim.inspect_pos()

  local lines = build_lines(
    vim.tbl_map(function(syntax)
      return syntax.hl_group_link
    end, items.syntax),
    vim.tbl_map(function(capture)
      return { capture.capture, capture.hl_group_link }
    end, items.treesitter),
    vim.tbl_map(function(extmark)
      return string.format(
        '%s (ns:%s prio:%s)',
        extmark.opts.hl_group,
        extmark.ns,
        extmark.opts.priority or 0
      )
    end, vim.list_extend(items.semantic_tokens, items.extmarks)),
    collect_matches()
  )

  local buf, win = open_popup(lines, items.row, items.col)
  attach_lifecycle(buf, win, origin_buf, origin_win)
end

return M
