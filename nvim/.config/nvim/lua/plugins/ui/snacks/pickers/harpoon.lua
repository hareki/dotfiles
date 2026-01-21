local M = {}

M.show = function(user_opts)
  local harpoon = require('harpoon')
  local buffer_format = require('plugins.ui.snacks.utils').buffer_format

  local function build_harpoon_items()
    local items = {}
    for idx, item in ipairs(harpoon:list().items) do
      local filepath = item.value
      local bufnr = vim.fn.bufnr(filepath)
      local valid_buf = bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr)

      items[#items + 1] = {
        idx = idx,
        file = filepath,
        buf = valid_buf and bufnr or nil,
        bufnr = valid_buf and bufnr or nil,
        name = vim.fs.basename(filepath),
        buftype = valid_buf and vim.bo[bufnr].buftype or '',
        filetype = valid_buf and vim.bo[bufnr].filetype or '',
        text = filepath,
      }
    end
    return items
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
    format = buffer_format,
  }, user_opts or {})

  local function remove_harpoon_item(picker)
    local selection = picker:selected({ fallback = true })
    if not selection or not selection[1] then
      return
    end

    picker:norm(function()
      local indices = {}
      for _, item in ipairs(selection) do
        if item.idx then
          table.insert(indices, item.idx)
        end
      end

      local list = harpoon:list()
      local to_remove = {}
      for _, idx in ipairs(indices) do
        to_remove[idx] = true
      end

      local items_to_keep = {}
      for i = 1, list:length() do
        if not to_remove[i] then
          local item = list:get(i)
          if item then
            table.insert(items_to_keep, item)
          end
        end
      end

      -- Rebuild harpoon list
      -- Can't use list:remove_at, it leaves a hole in the array
      -- Can't use table.remoe, harpoon doesn't update its internal state correctly
      list:clear()
      for _, item in ipairs(items_to_keep) do
        list:add(item)
      end
    end)

    local refreshed = build_harpoon_items()

    picker.opts.items = refreshed
    picker:refresh()
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
