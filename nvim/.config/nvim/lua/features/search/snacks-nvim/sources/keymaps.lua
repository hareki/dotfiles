--- @module 'snacks'
--- The keymaps picker's pieces: descs filled from which-key, noise filtered, aligned columns
--- @class features.search.snacks-nvim.sources.keymaps
local M = {}

local FILTERED_DESCRIPTIONS = {
  'blink.cmp',
  'autopairs map key', -- nvim-autopairs
}

--- Query spec descriptions from which-key mappings
--- @param lhs string
--- @param mode string
--- @param buffer? number
--- @return string? desc
local function query_spec_desc(lhs, mode, buffer)
  local wk_config = require('which-key.config')
  -- nvim_get_keymap resolves mapleader while which-key specs keep <leader>; normkey unifies them
  local normkey = Snacks.util.normkey
  lhs = normkey(lhs)

  -- First matching spec wins
  for _, mapping in ipairs(wk_config.mappings) do
    if
      mapping.mode == mode
      and (buffer == nil or buffer == 0 or mapping.buffer == buffer)
      and normkey(mapping.lhs) == lhs
    then
      return mapping.desc
    end
  end

  return nil
end

--- Transform function for keymap picker: fill missing descs from which-key, filter unwanted maps
--- @param item snacks.picker.Item
--- @return snacks.picker.Item | false item false to filter it out
function M.transform(item)
  local keymap = item.item
  item.file = nil -- We're not showing the file column anyway

  if not keymap.desc then
    keymap.desc = query_spec_desc(keymap.lhs, keymap.mode, keymap.buffer)
    if keymap.desc then
      item.text = item.text .. keymap.desc
    end
  end

  if keymap.desc then
    for _, v in ipairs(FILTERED_DESCRIPTIONS) do
      if keymap.desc:find(v, 1, true) then
        return false
      end
    end
  end

  return item
end

--- Format function for keymap picker (icon, description, buffer, lhs, mode)
--- @param item snacks.picker.Item
--- @param width integer
--- @return snacks.picker.Highlight[] highlights
function M.format(item, width)
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

return M
