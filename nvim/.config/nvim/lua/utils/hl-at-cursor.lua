local icons = require('config.icons')
local layout = require('utils.ui.layout')
local popup = require('utils.popup')

--- @class utils.hl-at-cursor
local M = {}

--- Closer of the open popup: a second would fight it over <Tab>/<Esc> and orphan the first float
--- @type fun()?
local close_active

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

--- @return integer win
local function open_popup(lines, row0, col0)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false

  local maxw = vim.fn.max(vim.tbl_map(vim.fn.strdisplaywidth, lines))

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 1,
    width = math.max(28, maxw + 2),
    height = math.min(#lines, layout.inline_max_height()),
    style = 'minimal',
    border = 'rounded',
    title = string.format(' Highlights (%d, %d) ', row0 + 1, col0 + 1),
    title_pos = 'center',
  })

  vim.bo[buf].filetype = 'markdown'
  vim.wo[win].conceallevel = 2
  vim.wo[win].wrap = false

  return win
end

--- Show the syntax groups, Tree-sitter captures, extmarks and matches at the cursor in a popup
--- @return nil
function M.show()
  if close_active then
    close_active()
  end

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
          icons.misc.ARROW,
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
    {
      '4. Matches',
      vim.tbl_map(function(match)
        return group_item(match.group)
      end, vim.fn.getmatches()),
    },
  })

  local win = open_popup(lines, items.row, items.col)

  -- <Esc> in the origin window also clears search highlights, as it does without the popup
  close_active = popup.link(win, {
    name = 'Highlight Popup',
    esc_passthrough = true,
    close_on = { cursor_moved = true, focus_left = true },
    on_close = function()
      close_active = nil
    end,
  })
end

return M
