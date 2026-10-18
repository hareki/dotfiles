--- @module 'snacks'
--- @class features.search.snacks.utils.finders
local M = {}

--- @class features.search.snacks.utils.finders.TabItem: snacks.picker.finder.Item
--- @field tab integer
--- @field label string The tab's statusline name (e.g. "tab-2" or "codediff-2"), padded to the widest

--- Finder for the tabs picker: one item per tabpage, previewing its active window's buffer
--- @param _ snacks.picker.Config
--- @param ctx snacks.picker.finder.ctx
--- @return features.search.snacks.utils.finders.TabItem[] items
function M.tabs(_, ctx)
  local tab_component = require('chrome.lualine-nvim.components.tab')
  local current_tab = vim.api.nvim_get_current_tabpage()
  local items = {} --- @type features.search.snacks.utils.finders.TabItem[]
  local label_width = 0

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    -- The current tab's active window is the picker's own input float; use the window
    -- the picker returns to instead
    local win = tab == current_tab and ctx.picker.main or vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    local item = {
      tab = tab,
      label = tab_component.name(tab),
      buf = buf,
      name = name,
      filetype = vim.bo[buf].filetype,
      file = name ~= '' and name or '[Scratch]',
      pos = vim.api.nvim_win_get_cursor(win),
    }
    item.text = Snacks.picker.util.text(item, { 'label', 'name', 'filetype' })
    items[#items + 1] = item
    label_width = math.max(label_width, #item.label)
  end

  -- Pad every label to the widest ("tab-1" vs "codediff-2") so the file columns line up
  for _, item in ipairs(items) do
    item.label = Snacks.picker.util.align(item.label, label_width)
  end

  return items
end

return M
