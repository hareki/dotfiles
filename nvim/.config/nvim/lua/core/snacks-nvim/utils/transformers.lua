--- @module 'snacks'
--- @class core.snacks.utils.transformers
local M = {}

local filtered_descriptions = {
  'blink.cmp',
  'autopairs map key', -- nvim-autopairs
}

local function is_ds_store(path)
  return type(path) == 'string' and path:match('%.DS_Store$') ~= nil
end

--- Query spec descriptions from which-key mappings
--- @param lhs string The left-hand side (key binding) to search for (required)
--- @param mode string The mode to search for (required)
--- @param buffer? number The buffer id to search for (optional)
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

--- Transform function for file picker to filter out .DS_Store files
--- @param item snacks.picker.Item The picker item to transform
--- @return snacks.picker.Item | false item The item or false to filter out
function M.files_transform(item)
  if is_ds_store(item.file) then
    return false
  end

  return item
end

--- Transform function for keymap picker to enrich with which-key descriptions
--- Looks up descriptions from which-key config and filters unwanted mappings.
--- @param item snacks.picker.Item The picker item to transform
--- @return snacks.picker.Item | false item The enriched item or false to filter out
function M.keymap_transform(item)
  local keymap_registry = require('config.keymap-registry')
  local desc_overrides = keymap_registry.DESC_OVERRIDES
  local keymap = item.item
  local old_desc = keymap.desc
  -- nvim_get_keymap reports the resolved lhs (mapleader as a literal space),
  -- while the registry keys use <leader> notation for the which-key path;
  -- normalize before the lookup
  local lhs = keymap.lhs
  local leader = vim.g.mapleader
  if type(leader) == 'string' and leader ~= '' then
    lhs = lhs:gsub(vim.pesc(leader), '<leader>')
  end
  local override_spec = desc_overrides[lhs]
  local override_desc = override_spec
    and vim.list_contains(override_spec.mode, keymap.mode)
    and override_spec.desc
  local new_desc = override_desc
    or keymap.desc
    or query_spec_desc(keymap.lhs, keymap.mode, keymap.buffer)

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

return M
