---@class plugins.core.snacks.utils.formatters
local M = {}

---Format function for keymap picker (icon, description, buffer, lhs, mode)
---Removes rhs and file columns from default format.
---@param item snacks.picker.Item The picker item
---@param _picker snacks.Picker The picker instance
---@param width integer Available width for formatting
---@return snacks.picker.Highlight[] highlights Array of highlight segments
function M.keymap_format(item, _picker, width)
  local ret = {} ---@type snacks.picker.Highlight[]
  ---@type wk.Keymap
  local k = item.item
  local align = Snacks.picker.util.align
  local col_width = {
    icon = 3,
    buffer = 6,
    lhs = 15,
    mode = 1,
  }
  local common = require('utils.common')
  local col_count = common.count_string_keys(col_width)

  local desc_width = width
    - col_width.icon
    - col_width.buffer
    - col_width.lhs
    - col_width.mode
    - col_count
    - 3

  if package.loaded['which-key'] then
    local Icons = require('which-key.icons')
    local icon, hl = Icons.get({ keymap = k, desc = k.desc })
    if icon then
      ret[#ret + 1] = { align(icon, col_width.icon), hl }
    else
      ret[#ret + 1] = { align('', col_width.icon) }
    end
  end
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

---Format function for buffer picker with modified indicator
---Removes buf number, buf type, and flags from default format.
---Adds modified indicator
---@param item snacks.picker.Item The picker item
---@param picker snacks.Picker The picker instance
---@return snacks.picker.Highlight[] highlights Array of highlight segments
function M.buffer_format(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  vim.list_extend(ret, Snacks.picker.format.filename(item, picker))

  if item.name == '' and item.filetype ~= '' then
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, {
      { '[', 'SnacksPickerDelim' },
      { item.filetype, 'SnacksPickerFileType' },
      { ']', 'SnacksPickerDelim' },
    })
  end

  local bufnr = item.buf or item.bufnr or (item.item and item.item.bufnr)
  if bufnr and vim.bo[bufnr].modified then
    ret[#ret + 1] = { Icons.file_status.modified, 'ModifiedIndicator' }
  end

  return ret
end

---Format function for buffer select picker (index + buffer format)
---Adds index number prefix to buffer_format output.
---@param item snacks.picker.Item The picker item
---@param picker snacks.Picker The picker instance
---@return snacks.picker.Highlight[] highlights Array of highlight segments
function M.buffer_select_format(item, picker)
  local count = picker:count()
  local ret = {} ---@type snacks.picker.Highlight[]
  local idx = tostring(item.idx)
  idx = (' '):rep(#tostring(count) - #idx) .. idx
  ret[#ret + 1] = { idx .. '.', 'SnacksPickerIdx' }
  ret[#ret + 1] = { ' ' }
  vim.list_extend(ret, M.buffer_format(item, picker))
  return ret
end

return M
