--- @class features.search.snacks.utils.formatters
local M = {}

--- Format function for keymap picker (icon, description, buffer, lhs, mode)
--- @param item snacks.picker.Item
--- @param width integer
--- @return snacks.picker.Highlight[] highlights
function M.keymap_format(item, width)
  local ret = {} --- @type snacks.picker.Highlight[]
  --- @type wk.Keymap
  local k = item.item
  local align = Snacks.picker.util.align
  local col_width = {
    icon = 3,
    buffer = 6,
    lhs = 15,
    mode = 1,
  }
  local col_count = vim.tbl_count(col_width)

  local desc_width = width
    - col_width.icon
    - col_width.buffer
    - col_width.lhs
    - col_width.mode
    - col_count
    - 3

  local wk_icons = require('which-key.icons')
  local icon, hl = wk_icons.get({ keymap = k, desc = k.desc })
  ret[#ret + 1] = { align(icon or '', col_width.icon), hl }
  ret[#ret + 1] = { align(k.desc or '', desc_width, { align = 'left', truncate = true }) }
  ret[#ret + 1] = { ' ' }

  local lhs = Snacks.util.normkey(k.lhs)
  if k.buffer and k.buffer > 0 then
    ret[#ret + 1] = { align('buf:' .. k.buffer, col_width.buffer), 'SnacksPickerBufNr' }
  else
    ret[#ret + 1] = { align('', col_width.buffer) }
  end
  ret[#ret + 1] = { ' ' }
  ret[#ret + 1] =
    { align(lhs, col_width.lhs, { align = 'right', truncate = true }), 'SnacksPickerKeymapLhs' }
  ret[#ret + 1] = { ' ' }
  ret[#ret + 1] = { align(k.mode, col_width.mode), 'SnacksPickerKeymapMode' }

  return ret
end

--- Format function for buffer picker: a modified indicator instead of buf number, type and flags
--- @param item snacks.picker.Item
--- @param picker snacks.Picker
--- @return snacks.picker.Highlight[] highlights
function M.buffer_format(item, picker)
  local ret = {} --- @type snacks.picker.Highlight[]
  vim.list_extend(ret, Snacks.picker.format.filename(item, picker))

  if item.name == '' and item.filetype ~= '' then
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, {
      { '[', 'SnacksPickerDelim' },
      { item.filetype, 'SnacksPickerFileType' },
      { ']', 'SnacksPickerDelim' },
    })
  end

  -- Runs per visible row on every render: vim.bo would switch into the autocmd window (~10us)
  if item.buf and vim.fn.getbufvar(item.buf, '&modified') == 1 then
    ret[#ret + 1] = { Conf.icons.file_status.MODIFIED, 'ModifiedIndicator' }
  end

  return ret
end

--- Format function for tabs picker: the tab's statusline name, then its active buffer's format
--- @param item snacks.picker.Item
--- @param picker snacks.Picker
--- @return snacks.picker.Highlight[] highlights
function M.tab_format(item, picker)
  local ret = { --- @type snacks.picker.Highlight[]
    { item.label, 'SnacksPickerTabName' },
    { '  ' },
  }

  vim.list_extend(ret, M.buffer_format(item, picker))
  return ret
end

return M
