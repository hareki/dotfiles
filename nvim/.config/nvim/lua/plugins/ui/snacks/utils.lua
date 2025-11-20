local M = {}

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

M.cache = {}

-- Set up autocmd to clean up cache entries when buffers are deleted
vim.api.nvim_create_autocmd('BufDelete', {
  callback = function(event)
    local buf_pattern = ':' .. event.buf .. '$'
    for key in pairs(M.cache) do
      if key:match(buf_pattern) then
        M.cache[key] = nil
      end
    end
  end,
})

local function query_spec_desc_cached(lhs, mode, buffer)
  buffer = buffer or vim.api.nvim_get_current_buf()
  local cache_key = string.format('%s:%s:%d', lhs, mode, buffer)

  if M.cache[cache_key] then
    return M.cache[cache_key]
  end

  local result = query_spec_desc(lhs, mode, buffer)
  M.cache[cache_key] = result
  return result
end

local filtered_descriptions = {
  'blink.cmp',
  'autopairs map key', -- nvim-autopairs
}

local function is_ds_store(path)
  return type(path) == 'string' and path:match('%.DS_Store$') ~= nil
end

function M.files_transform(item)
  if is_ds_store(item.file) then
    return false
  end
end

function M.keymap_transform(item)
  local desc_overrides = require('plugins.editor.which-key.preset').desc_overrides
  local keymap = item.item
  local old_desc = keymap.desc
  local override_spec = desc_overrides[keymap.lhs]
  local override_desc = override_spec
    and vim.tbl_contains(override_spec.mode, keymap.mode)
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

-- Remove the rhs and file columns from
-- https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/format.lua#L449
function M.keymap_format(item, _picker, width)
  local ret = {} ---@type snacks.picker.Highlight[]
  ---@type vim.api.keyset.get_keymap
  local k = item.item
  local align = Snacks.picker.util.align
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

-- Remove buf number and flags from
-- https://github.com/folke/snacks.nvim/blob/52f30a198a19bf5da6aa95cc642bfbb99b9bbfbf/lua/snacks/picker/format.lua#L638
---@param item snacks.picker.Item
function M.buffer_format(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  vim.list_extend(ret, Snacks.picker.format.filename(item, picker))

  if item.buftype ~= '' then
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, {
      { '[', 'SnacksPickerDelim' },
      { item.buftype, 'SnacksPickerBufType' },
      { ']', 'SnacksPickerDelim' },
    })
  end

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
    ret[#ret + 1] = { require('configs.icons').file_status.modified, 'Number' }
  end

  return ret
end

return M
