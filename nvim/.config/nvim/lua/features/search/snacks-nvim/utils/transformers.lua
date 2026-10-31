--- @module 'snacks'
--- @class features.search.snacks.utils.transformers
local M = {}

local filtered_descriptions = {
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
function M.keymap_transform(item)
  local keymap = item.item
  item.file = nil -- We're not showing the file column anyway

  if not keymap.desc then
    keymap.desc = query_spec_desc(keymap.lhs, keymap.mode, keymap.buffer)
    if keymap.desc then
      item.text = item.text .. keymap.desc
    end
  end

  if keymap.desc then
    for _, v in ipairs(filtered_descriptions) do
      if keymap.desc:find(v, 1, true) then
        return false
      end
    end
  end

  return item
end

--- Transform function for buffer picker: flag modified buffers for the `modified` sort field
--- @param item snacks.picker.Item
--- @return nil
function M.buffer_transform(item)
  -- The matcher sorts from snacks' async loop, a fast event context where vim.bo raises
  -- E5560, so the sort key comes from the buffers finder's getbufinfo() snapshot
  item.modified = item.info.changed == 1
end

return M
