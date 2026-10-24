local common = require('utils.common')

--- @class utils.hl-at-cursor
local M = {}

-- Closer of the open popup: only one may exist, or a second would fight the first over the
-- origin buffer's <Tab>/<Esc> keymaps and orphan the earlier float
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

--- Render the popup's markdown: a bold title per section, then its unique items or 'none'
--- @param sections { [1]: string, [2]: string[] }[] Section titles and their list items
--- @return string[]
local function build_lines(sections)
  local lines = {}
  for _, section in ipairs(sections) do
    table.insert(lines, '**' .. section[1] .. '**')
    local items = vim.list.unique(section[2])
    vim.list_extend(lines, #items > 0 and items or { 'none' })
  end
  return lines
end

--- A markdown list item naming a highlight group, with an optional note after it
--- @param group string
--- @param note? string
--- @return string
local function group_item(group, note)
  return string.format('- `%s`%s', group, note and (' ' .. note) or '')
end

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

--- Wire the popup's lifecycle: linked focus/close keys, and closing it once the cursor or
--- focus leaves the popup and its origin
local function attach_lifecycle(buf, win, origin_buf, origin_win)
  -- Re-entering origin_win fires CursorMoved even though its cursor never moved
  local origin_pos = vim.api.nvim_win_get_cursor(origin_win)
  local augroup = vim.api.nvim_create_augroup('utils.hl-at-cursor.popup-' .. win, { clear = true })

  local function close_popup()
    if close_active_popup == close_popup then
      close_active_popup = nil
    end
    -- Deleted before the close, so the popup's WinClosed can't come back here
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
    pcall(vim.api.nvim_win_close, win, true)
  end

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

  -- <Esc> in the origin window also clears search highlights, as it does without the popup
  common.link_popup(win, { name = 'Highlight Popup', esc_passthrough = true })

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

  local lines = build_lines({
    {
      '1. Syntax',
      vim.tbl_map(function(syntax)
        return group_item(syntax.hl_group_link)
      end, items.syntax),
    },
    {
      '2. Tree-sitter',
      vim.tbl_map(function(capture)
        return string.format(
          '- `@%s` %s `%s`',
          capture.capture,
          Conf.icons.misc.ARROW,
          capture.hl_group_link
        )
      end, items.treesitter),
    },
    {
      '3. Extmarks',
      vim.tbl_map(function(extmark)
        return group_item(
          extmark.opts.hl_group,
          string.format('(ns:%s prio:%s)', extmark.ns, extmark.opts.priority or 0)
        )
      end, vim.list_extend(items.semantic_tokens, items.extmarks)),
    },
    { '4. Matches', vim.tbl_map(group_item, collect_matches()) },
  })

  local buf, win = open_popup(lines, items.row, items.col)
  attach_lifecycle(buf, win, origin_buf, origin_win)
end

return M
