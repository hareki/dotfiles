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
--- @return string? # The description of the first matching spec, or nil if not found
local function query_spec_desc(lhs, mode, buffer)
  local wk_config = require('which-key.config')

  -- First matching spec wins
  for _, mapping in ipairs(wk_config.mappings) do
    if
      mapping.lhs == lhs
      and mapping.mode == mode
      and (buffer == nil or buffer == 0 or mapping.buffer == buffer)
    then
      return mapping.desc
    end
  end

  return nil
end

--- Transform function for keymap picker to enrich with which-key descriptions
--- Looks up descriptions from which-key config and filters unwanted mappings.
--- @param item snacks.picker.Item
--- @return snacks.picker.Item | false item The enriched item or false to filter out
function M.keymap_transform(item)
  local keymap = item.item
  local old_desc = keymap.desc
  -- nvim_get_keymap reports the resolved lhs (mapleader as a literal space), while which-key specs
  -- keep <leader> notation; normalize before the lookup
  local lhs = keymap.lhs
  local leader = vim.g.mapleader
  if type(leader) == 'string' and leader ~= '' then
    lhs = lhs:gsub(vim.pesc(leader), '<leader>')
  end
  local new_desc = keymap.desc or query_spec_desc(lhs, keymap.mode, keymap.buffer)

  item.file = nil -- We're not showing the file column anyway
  item.item.desc = new_desc
  if old_desc ~= new_desc then
    item.text = item.text .. new_desc
  end

  if new_desc then
    for _, v in ipairs(filtered_descriptions) do
      if new_desc:find(v, 1, true) then
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
