---@class plugins.ui.snacks.utils.transformers
local M = {}

local cache = require('plugins.ui.snacks.utils.cache')

local filtered_descriptions = {
  'blink.cmp',
  'autopairs map key', -- nvim-autopairs
}

local function is_ds_store(path)
  return type(path) == 'string' and path:match('%.DS_Store$') ~= nil
end

---Query spec descriptions from which-key mappings
---@param lhs string The left-hand side (key binding) to search for (required)
---@param mode string The mode to search for (required)
---@param buffer? number The buffer id to search for (optional)
---@return string? # The description of the first matching spec, or nil if not found
local function query_spec_desc(lhs, mode, buffer)
  local wk_config = require('which-key.config')

  -- Traverse backward
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

local function query_spec_desc_cached(lhs, mode, buffer)
  buffer = buffer or vim.api.nvim_get_current_buf()
  local cache_key = string.format('%s:%s:%d', lhs, mode, buffer)

  if cache.cache[cache_key] then
    return cache.cache[cache_key]
  end

  local result = query_spec_desc(lhs, mode, buffer)
  cache.cache[cache_key] = result
  return result
end

---Transform function for file picker to filter out .DS_Store files
---@param item snacks.picker.Item The picker item to transform
---@return snacks.picker.Item|false item The item or false to filter out
function M.files_transform(item)
  if is_ds_store(item.file) then
    return false
  end
end

---Transform function for keymap picker to enrich with which-key descriptions
---Looks up descriptions from which-key config and filters unwanted mappings.
---@param item snacks.picker.Item The picker item to transform
---@return snacks.picker.Item|false item The enriched item or false to filter out
function M.keymap_transform(item)
  local desc_overrides = require('plugins.editor.which-key.preset').desc_overrides
  local keymap = item.item
  local old_desc = keymap.desc
  local override_spec = desc_overrides[keymap.lhs]
  local override_desc = override_spec
    and vim.list_contains(override_spec.mode, keymap.mode)
    and override_spec.desc
  local new_desc = override_desc
    or keymap.desc
    or query_spec_desc_cached(keymap.lhs, keymap.mode, keymap.buffer)

  item.file = nil -- We're not showing the file column anyway
  item.item.desc = new_desc
  if old_desc ~= new_desc then
    item.text = item.text .. new_desc
  end

  for _, v in ipairs(filtered_descriptions) do
    if new_desc and new_desc:find(v) then
      return false
    end
  end

  return item
end

---Transform function for buffer select picker (index + buffer format)
---Adds index number to the search text so it can be matched
---@param item snacks.picker.Item The picker item to transform
---@return snacks.picker.Item item The transformed item
function M.buffer_select_transform(item)
  if item.idx and item.text then
    item.text = item.idx .. ' ' .. item.text
  end
  return item
end

return M
