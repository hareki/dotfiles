local M = {}

-- Simplified version of: https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/format.lua#L449
-- Remove the rhs and file columns
function M.keymap_format(item, _picker, width)
  local ret = {} ---@type snacks.picker.Highlight[]
  ---@type vim.api.keyset.get_keymap
  local k = item.item
  local a = Snacks.picker.util.align
  local col_width = {
    icon = 3,
    buffer = 6,
    lhs = 15,
    mode = 1,
  }
  local col_count = require('utils.common').count_string_keys(col_width)

  local desc_width = width
    - col_width.icon
    - col_width.buffer
    - col_width.lhs
    - col_width.mode
    - col_count
    - 1 -- right padding, icon col already handles left padding

  if package.loaded['which-key'] then
    local Icons = require('which-key.icons')
    local icon, hl = Icons.get({ keymap = k, desc = k.desc })
    if icon then
      ret[#ret + 1] = { a(icon, col_width.icon), hl }
    else
      ret[#ret + 1] = { a('', col_width.icon) }
    end
  end
  ret[#ret + 1] = { a(k.desc or '', desc_width, { align = 'left', truncate = true }) }
  ret[#ret + 1] = { ' ' }

  local lhs = Snacks.util.normkey(k.lhs)
  if k.buffer and k.buffer > 0 then
    ret[#ret + 1] = { a('buf:' .. k.buffer, col_width.buffer), 'SnacksPickerBufNr' }
  else
    ret[#ret + 1] = { a('', col_width.buffer) }
  end
  ret[#ret + 1] = { ' ' }
  ret[#ret + 1] =
    { a(lhs, col_width.lhs, { align = 'right', truncate = true }), 'SnacksPickerKeymapLhs' }
  ret[#ret + 1] = { ' ' }
  ret[#ret + 1] = { a(k.mode, col_width.mode), 'SnacksPickerKeymapMode' }

  return ret
end

return M
