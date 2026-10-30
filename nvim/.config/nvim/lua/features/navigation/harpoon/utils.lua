--- @class features.navigation.harpoon.utils
local M = {}

--- Pin the current file to a slot, moving it out of any other slot it held
--- @param index integer Slot number
--- @return nil
function M.pin(index)
  local harpoon = require('harpoon')
  local list = harpoon:list()

  -- Item values are already relative to the cwd (absolute outside of it)
  local new_item = list.config.create_list_item(list.config)
  local old_item = list:get(index)

  if old_item and old_item.value == new_item.value then
    Notifier.warn({
      { new_item.value, 'NotifyWARNTitle' },
      { '\nis already in slot ', 'Normal' },
      { tostring(index), 'NotifyWARNTitle' },
    }, { title = 'Pin' })

    return
  end

  -- Check if new_item already exists at another index (the early
  -- return above rules out `index`)
  local _, old_index = list:get_by_value(new_item.value)

  -- replace_at also clears new_item from any other slot it held
  list:replace_at(index, new_item)

  if old_index then
    Notifier.warn({
      { 'Moved ', 'Normal' },
      { new_item.value, 'NotifyWARNTitle' },
      { '\nfrom slot ', 'Normal' },
      { tostring(old_index), 'NotifyWARNTitle' },
      { ' to ', 'Normal' },
      { tostring(index), 'NotifyWARNTitle' },
    }, { title = 'Pin' })
  elseif old_item then
    -- The early return above rules out the same item
    Notifier.warn({
      { 'Replaced ', 'Normal' },
      { old_item.value, 'NotifyWARNTitle' },
      { '\nwith ', 'Normal' },
      { new_item.value, 'NotifyWARNTitle' },
      { '\nfor slot ', 'Normal' },
      { tostring(index), 'NotifyWARNTitle' },
    }, { title = 'Pin' })
  else
    -- Slot was empty, new file added
    Notifier.info({
      { 'Added ', 'Normal' },
      { new_item.value, 'NotifyINFOTitle' },
      { '\ninto slot ', 'Normal' },
      { tostring(index), 'NotifyINFOTitle' },
    }, { title = 'Pin' })
  end
end

--- @return snacks.Picker | nil picker The picker instance, or nil if list is empty
M.show_picker = function()
  local harpoon = require('harpoon')
  local formatters = require('features.search.snacks-nvim.utils.formatters')

  local function build_harpoon_items()
    local items = {}
    local list = harpoon:list()
    local max_idx = list:length()

    for harpoon_idx = 1, max_idx do
      local item = list:get(harpoon_idx)
      if item then
        local filepath = item.value
        -- Exact lookup: vim.fn.bufnr() treats its argument as a file-pattern, so paths with magic
        -- chars ("app/[slug]/page.tsx") can match an unrelated buffer; bufexists() matches names
        -- exactly, and bufadd() then returns that buffer rather than creating one
        local abs = vim.fn.fnamemodify(filepath, ':p')
        local buf = vim.fn.bufexists(abs) == 1 and vim.fn.bufadd(abs) or nil

        items[#items + 1] = {
          harpoon_idx = harpoon_idx,
          file = filepath,
          buf = buf,
          name = vim.fs.basename(filepath),
          buftype = buf and vim.bo[buf].buftype or '',
          filetype = buf and vim.bo[buf].filetype or '',
          text = harpoon_idx .. ' ' .. filepath,
        }
      end
    end
    return items
  end

  --- Picker format: the harpoon index, then the buffer format
  --- @param item snacks.picker.Item
  --- @param picker snacks.Picker
  --- @return snacks.picker.Highlight[] highlights
  local function harpoon_format(item, picker)
    local ret = {} --- @type snacks.picker.Highlight[]
    local max_harpoon_idx = harpoon:list():length()
    local idx_str = Snacks.picker.util.align(
      tostring(item.harpoon_idx),
      #tostring(max_harpoon_idx),
      { align = 'right' }
    )
    ret[#ret + 1] = { idx_str .. '.', 'SnacksPickerIdx' }
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, formatters.buffer_format(item, picker))
    return ret
  end

  if harpoon:list():length() == 0 then
    Notifier.info('Pin list is empty')
    return
  end

  -- The statusline refresh after a removal comes from the REMOVE extension that
  -- the harpoon spec registers, which list:remove_at() emits
  local function remove_harpoon_item(picker)
    local selection = picker:selected({ fallback = true })
    if not selection[1] then
      return
    end

    picker:norm(function()
      local list = harpoon:list()
      local indices_to_remove = {}
      for _, item in ipairs(selection) do
        table.insert(indices_to_remove, item.harpoon_idx)
      end

      table.sort(indices_to_remove, function(a, b)
        return a > b
      end)

      for _, idx in ipairs(indices_to_remove) do
        list:remove_at(idx)
      end
    end)

    picker:refresh()
  end

  return Snacks.picker({
    title = 'Pinned Files',
    finder = build_harpoon_items,
    source = 'harpoon',
    format = harpoon_format,
    actions = {
      remove_harpoon_item = remove_harpoon_item,
    },
    win = {
      input = {
        keys = {
          ['x'] = { 'remove_harpoon_item', desc = 'Remove from Pin List' },
        },
      },
    },
  })
end

--- Invalidate the statusline's harpoon component and redraw it. Some mutations keep the list
--- length (replace_at, menu-save reorder), so the component's (buf, length) cache key misses them
--- @return nil
function M.refresh_statusline()
  local harpoon_component = require('chrome.lualine-nvim.components.harpoon')
  harpoon_component.invalidate()
  UI.statusline.refresh()
end

return M
