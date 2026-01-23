local M = {}

M.show = function(user_opts)
  local harpoon = require('harpoon')
  local formatters = require('plugins.ui.snacks.utils.formatters')

  local function build_harpoon_items()
    local items = {}
    local list = harpoon:list()
    local max_idx = list:length()

    for harpoon_idx = 1, max_idx do
      local item = list:get(harpoon_idx)
      if item then
        local filepath = item.value
        local bufnr = vim.fn.bufnr(filepath)
        local valid_buf = bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr)

        items[#items + 1] = {
          harpoon_idx = harpoon_idx,
          idx = harpoon_idx,
          file = filepath,
          buf = valid_buf and bufnr or nil,
          bufnr = valid_buf and bufnr or nil,
          name = vim.fs.basename(filepath),
          buftype = valid_buf and vim.bo[bufnr].buftype or '',
          filetype = valid_buf and vim.bo[bufnr].filetype or '',
          text = filepath,
        }
      end
    end
    return items
  end

  ---Format function for harpoon picker (harpoon index + buffer format)
  ---Adds harpoon index number prefix to buffer_format output.
  ---@param item snacks.picker.Item The picker item
  ---@param picker snacks.Picker The picker instance
  ---@return snacks.picker.Highlight[] highlights Array of highlight segments
  local function harpoon_format(item, picker)
    local ret = {} ---@type snacks.picker.Highlight[]
    local max_harpoon_idx = harpoon:list():length()
    local harpoon_idx = item.harpoon_idx or item.idx
    local idx_str = tostring(harpoon_idx)
    idx_str = (' '):rep(#tostring(max_harpoon_idx) - #idx_str) .. idx_str
    ret[#ret + 1] = { idx_str .. '.', 'SnacksPickerIdx' }
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, formatters.buffer_format(item, picker))
    return ret
  end

  local function harpoon_transform(item)
    if item.harpoon_idx and item.text then
      item.text = item.harpoon_idx .. ' ' .. item.text
    elseif item.idx and item.text then
      item.text = item.idx .. ' ' .. item.text
    end
    return item
  end

  local items = build_harpoon_items()
  if vim.tbl_isempty(items) then
    Notifier.info('Harpoon list is empty')
    return
  end

  local opts = vim.tbl_deep_extend('force', {
    title = 'Harpoon',
    items = items,
    source = 'harpoon',
    format = harpoon_format,
    transform = harpoon_transform,
  }, user_opts or {})

  local function remove_harpoon_item(picker)
    local selection = picker:selected({ fallback = true })
    if not selection or not selection[1] then
      return
    end

    picker:norm(function()
      local list = harpoon:list()
      local indices_to_remove = {}
      for _, item in ipairs(selection) do
        local harpoon_idx = item.harpoon_idx or item.idx
        if harpoon_idx then
          table.insert(indices_to_remove, harpoon_idx)
        end
      end

      table.sort(indices_to_remove, function(a, b)
        return a > b
      end)

      for _, idx in ipairs(indices_to_remove) do
        list:remove_at(idx)
      end
    end)

    local refreshed = build_harpoon_items()

    picker.opts.items = refreshed
    picker:refresh()

    require('plugins.ui.lualine.utils').refresh_statusline()
  end

  opts.actions = opts.actions or {}
  opts.actions.remove_harpoon_item = remove_harpoon_item

  opts.win = opts.win or {}
  opts.win.input = opts.win.input or {}
  opts.win.input.keys = opts.win.input.keys or {}
  opts.win.input.keys['x'] = { 'remove_harpoon_item', mode = { 'n' }, desc = 'Remove from Harpoon' }

  return Snacks.picker(opts)
end

return M
