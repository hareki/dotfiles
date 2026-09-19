--- @class core.snacks.pickers.sources.harpoon
local M = {}

--- Show the harpoon picker with items from the harpoon list
--- @return snacks.Picker | nil picker The picker instance, or nil if list is empty
M.show = function()
  local harpoon = require('harpoon')
  local formatters = require('core.snacks-nvim.utils.formatters')

  local function build_harpoon_items()
    local items = {}
    local list = harpoon:list()
    local max_idx = list:length()

    for harpoon_idx = 1, max_idx do
      local item = list:get(harpoon_idx)
      if item then
        local filepath = item.value
        -- Compare names exactly: vim.fn.bufnr() treats its argument as a
        -- file-pattern, so paths with magic chars (e.g. "app/[slug]/page.tsx")
        -- can pattern-match an unrelated buffer
        local abs = vim.fn.fnamemodify(filepath, ':p')
        local bufnr = -1
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(b) == abs then
            bufnr = b
            break
          end
        end
        local valid_buf = bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr)

        items[#items + 1] = {
          harpoon_idx = harpoon_idx,
          idx = harpoon_idx,
          file = filepath,
          buf = valid_buf and bufnr or nil,
          name = vim.fs.basename(filepath),
          buftype = valid_buf and vim.bo[bufnr].buftype or '',
          filetype = valid_buf and vim.bo[bufnr].filetype or '',
          -- Index prefix is built here, not in a transform: snacks re-runs
          -- transforms over these same item tables on every find(), so a
          -- mutating transform would re-prefix the text each time
          text = harpoon_idx .. ' ' .. filepath,
        }
      end
    end
    return items
  end

  --- Format function for harpoon picker (harpoon index + buffer format)
  --- Adds harpoon index number prefix to buffer_format output.
  --- @param item snacks.picker.Item The picker item
  --- @param picker snacks.Picker The picker instance
  --- @return snacks.picker.Highlight[] highlights Array of highlight segments
  local function harpoon_format(item, picker)
    local ret = {} --- @type snacks.picker.Highlight[]
    local max_harpoon_idx = harpoon:list():length()
    local idx_str = tostring(item.harpoon_idx)
    idx_str = (' '):rep(#tostring(max_harpoon_idx) - #idx_str) .. idx_str
    ret[#ret + 1] = { idx_str .. '.', 'SnacksPickerIdx' }
    ret[#ret + 1] = { ' ' }
    vim.list_extend(ret, formatters.buffer_format(item, picker))
    return ret
  end

  local items = build_harpoon_items()
  if vim.tbl_isempty(items) then
    Notifier.info('Pin list is empty')
    return
  end

  -- The statusline refresh after a removal comes from the REMOVE extension that
  -- the harpoon spec registers, which list:remove_at() emits
  local function remove_harpoon_item(picker)
    local selection = picker:selected({ fallback = true })
    if not selection or not selection[1] then
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

    picker.opts.items = build_harpoon_items()
    picker:refresh()
  end

  return Snacks.picker({
    title = 'Pinned Files',
    items = items,
    source = 'harpoon',
    format = harpoon_format,
    actions = {
      remove_harpoon_item = remove_harpoon_item,
    },
    win = {
      input = {
        keys = {
          ['x'] = { 'remove_harpoon_item', mode = { 'n' }, desc = 'Remove from Pin List' },
        },
      },
    },
  })
end

return M
