--- @module 'snacks'
--- The tabs picker: one item per tabpage, labeled like the statusline's tab pill
--- @class features.search.snacks-nvim.sources.tabs
local M = {}

--- @class snacks.picker
--- @field tabs fun(opts?: snacks.picker.Config | {}): snacks.Picker

--- @param tabpage integer
--- @return string label e.g. "tab-2" or "codediff-2"
function M.label(tabpage)
  local codediff_utils = require('features.git.codediff-nvim.utils')
  local prefix = codediff_utils.is_codediff_tab(tabpage) and 'codediff' or 'tab'

  return prefix .. '-' .. vim.api.nvim_tabpage_get_number(tabpage)
end

--- @class features.search.snacks-nvim.sources.tabs.Item: snacks.picker.finder.Item
--- @field tab integer
--- @field label string The tab's statusline name (e.g. "tab-2" or "codediff-2"), padded to the widest

--- Finder for the tabs picker: one item per tabpage, previewing its active window's buffer
--- @param _ snacks.picker.Config
--- @param ctx snacks.picker.finder.ctx
--- @return features.search.snacks-nvim.sources.tabs.Item[] items
local function finder(_, ctx)
  local current_tab = vim.api.nvim_get_current_tabpage()
  local items = {} --- @type features.search.snacks-nvim.sources.tabs.Item[]
  local label_width = 0

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    -- The current tab's active window is the picker's input float; use the one it returns to
    local win = tab == current_tab and ctx.picker.main or vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    local item = {
      tab = tab,
      label = M.label(tab),
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

--- Format function for tabs picker: the tab's statusline name, then its active buffer's format
--- @param item snacks.picker.Item
--- @param picker snacks.Picker
--- @return snacks.picker.Highlight[] highlights
local function format(item, picker)
  local ret = { --- @type snacks.picker.Highlight[]
    { item.label, 'SnacksPickerTabName' },
    { '  ' },
  }

  local buffers = require('features.search.snacks-nvim.sources.buffers')
  vim.list_extend(ret, buffers.format(item, picker))
  return ret
end

--- The tabs source's confirm: switch to the tabpage under the cursor
--- @param picker snacks.Picker
--- @param item? snacks.picker.Item The item under the cursor
--- @return nil
local function confirm(picker, item)
  -- Leave insert mode first, or picker:close()'s stopinsert moves the target tab's cursor
  picker:norm(function()
    picker:close()
    if item and vim.api.nvim_tabpage_is_valid(item.tab) then
      vim.api.nvim_set_current_tabpage(item.tab)
    end
  end)
end

--- Close the tabpage hosting the picker's floats and resume the picker where nvim lands
--- @param picker snacks.Picker
--- @return nil
local function close_current_tab(picker)
  local insert = vim.fn.mode():sub(1, 1) == 'i'

  -- Leave insert mode first, or picker:close()'s stopinsert lands where the tabclose leaves us
  picker:norm(function()
    picker.list:set_selected() -- Don't resume with the closed tabs still selected
    picker:close()
    vim.cmd.tabclose()

    -- Focusing the resumed input runs its BufEnter startinsert!, which restores insert mode
    local resumed = Snacks.picker.resume({ source = picker.opts.source })
    if not resumed or insert then
      return
    end

    -- Cancel that startinsert! so x can be repeated. The picker shows synchronously when resumed
    -- with an empty pattern (the matcher's fast path), otherwise later, right before on_show runs
    if resumed.shown then
      vim.cmd.stopinsert()
    else
      resumed.opts.on_show = function()
        vim.cmd.stopinsert()
      end
    end
  end)
end

--- Close the selected tabpages (or the one under the cursor), the tabs source's bufdelete
--- @param picker snacks.Picker
--- @return nil
local function tab_close(picker)
  picker.preview:reset()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local close_current = false

  for _, item in ipairs(picker:selected({ fallback = true })) do
    if item.tab == current_tab then
      close_current = true -- Closing it takes the picker with it, so it goes last
    elseif vim.api.nvim_tabpage_is_valid(item.tab) then
      vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(item.tab))
    end
  end

  if close_current then
    if #vim.api.nvim_list_tabpages() > 1 then
      close_current_tab(picker)
      return
    end
    Notifier.warn('Cannot close the last tab', { title = 'Snacks Picker' }) -- E784
  end

  picker:refresh()
end

--- The tabs source's config, which the search fragment registers as `picker.sources.tabs`
--- @type snacks.picker.Config
M.source = {
  finder = finder,
  format = format,
  confirm = confirm,
  actions = {
    tab_close = tab_close,
  },
  win = {
    input = {
      keys = {
        ['<C-x>'] = { 'tab_close', mode = { 'n', 'i' } },
        ['x'] = 'tab_close', -- close selected tab from input (normal mode)
      },
    },
    list = { keys = { ['dd'] = 'tab_close' } },
  },
}

return M
