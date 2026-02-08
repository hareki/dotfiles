---@class nvim-tree.utils
local M = {}

---@alias nvim-tree.utils.Position  'side' | 'float'

---@class nvim-tree.utils.State
---@field position nvim-tree.utils.Position
---@field opts table | nil
---@field preview_on_focus boolean
---@field preview_watcher integer | nil
---@field live_filter_triggered boolean
---@field size 'vertical_lg'

---@type nvim-tree.utils.State
M.state = {
  position = 'float',
  opts = nil,
  preview_on_focus = false, -- Preview is off on startup
  preview_watcher = nil,
  live_filter_triggered = false,
  size = 'vertical_lg',
}

---Clean up the preview watcher autocmd group
---@return nil
function M.clean_up()
  if M.state.preview_watcher == nil then
    return
  end

  vim.api.nvim_clear_autocmds({ group = M.state.preview_watcher })
  vim.api.nvim_del_augroup_by_id(M.state.preview_watcher)
  M.state.preview_watcher = nil
end

---Close the nvim-tree and preview windows, cleaning up watchers
---@return nil
function M.close_all()
  local api = require('nvim-tree.api')
  local preview = require('nvim-tree-preview')

  M.clean_up()

  preview.unwatch()
  api.tree.close()
end

---Start watching for cursor movement to update preview
---@return nil
function M.watch()
  local preview = require('nvim-tree-preview')

  if not preview.is_open() then
    preview.watch()
    M.state.preview_on_focus = true
  end
end

---Stop watching cursor movement for preview updates
---@return nil
function M.unwatch()
  local preview = require('nvim-tree-preview')
  preview.unwatch()
  M.state.preview_on_focus = false
end

---Create a node action function for file/folder interaction
---For files: opens the file and closes tree if floating.
---For folders: expands, collapses, or toggles based on action type.
---@param folder_action 'expand' | 'collapse' | 'toggle' The action to perform on folders
---@return function action The node action function
function M.create_node_action(folder_action)
  return function()
    local api = require('nvim-tree.api')

    local ok, node = pcall(api.tree.get_node_under_cursor)
    if not ok or not node then
      return
    end

    local is_file_node = node.nodes == nil

    if is_file_node then
      api.node.open.edit()
      if M.state.position == 'float' then
        M.close_all()
      end
      return
    end

    if
      folder_action == 'toggle'
      or folder_action == 'expand' and not node.open
      or folder_action == 'collapse' and node.open
    then
      api.node.open.edit()
    end
  end
end

---Switch nvim-tree between float and side panel positions
---@param position nvim-tree.utils.Position The target position ('float' or other)
---@return nil
function M.switch_position(position)
  if position == M.state.position then
    return
  end

  local nvimtree = require('nvim-tree')

  M.state.position = position
  if M.state.opts ~= nil then
    M.state.opts.view.float.enable = position == 'float'
  end

  M.close_all()
  -- nvim-tree explicitly supports subsequent setup calls:
  -- https://github.com/nvim-tree/nvim-tree.lua/blob/b0b49552c9462900a882fe772993b01d780445fe/lua/nvim-tree.lua#L738
  nvimtree.setup(M.state.opts)
end

---Toggle the tree window height between half and full in float mode
---@param action 'expand' | 'collapse' The height action to perform
---@return nil
function M.toggle_tree_height(action)
  if M.state.position ~= 'float' then
    return
  end

  local api = require('nvim-tree.api')
  local tree_win = api.tree.winid()

  if tree_win == nil then
    return
  end

  local ui_utils = require('utils.ui')
  local size = ui_utils.popup_config(M.state.size)
  local window_h = math.floor(size.height / 2)
  local half_height = window_h - 1 -- Minus 1 for the space between the two windows

  -- Have to add one extra row if the total height is an odd number to fill out the entire popup size
  local offset = ui_utils.popup_config(M.state.size).height % 2 == 0 and 0 or 1
  local full_height = window_h * 2 + offset

  local cfg = vim.api.nvim_win_get_config(tree_win)

  if action == 'collapse' then
    cfg.height = half_height
  else
    cfg.height = full_height
  end

  vim.api.nvim_win_set_config(tree_win, cfg)
end

---Toggle the preview window open/closed state
---Adjusts tree height in float mode and manages watch state.
---@param force_state boolean|nil Force specific state (true=open, false=close, nil=toggle)
---@return nil
function M.toggle_preview(force_state)
  local api = require('nvim-tree.api')
  local preview = require('nvim-tree-preview')

  local tree_win = api.tree.winid()

  if not tree_win or not vim.api.nvim_win_is_valid(tree_win) then
    return
  end

  local is_preview_open = preview.is_open()
  local next_open = not is_preview_open

  if force_state ~= nil then
    next_open = force_state
  end

  local toggle_height = M.state.position == 'float'

  if next_open then
    if toggle_height then
      M.toggle_tree_height('collapse')
    end
    M.watch()
  else
    if toggle_height then
      M.toggle_tree_height('expand')
    end
    M.unwatch()
  end
end

---Toggle focus between nvim-tree and preview window
---@return nil
function M.toggle_focus()
  local manager = require('nvim-tree-preview.manager')
  manager.instance:toggle_focus()
end

---@class nvim-tree.OpenParams
---@field switching boolean|nil

---Open nvim-tree with optional switching behavior
---Resets to float position if not switching and tree is not visible.
---@param opts nvim-tree.OpenParams|nil Options with switching flag
---@return nil
function M.open(opts)
  local api = require('nvim-tree.api')
  local switching = opts and opts.switching or false

  -- Reset the position back to 'float' when opening the tree
  if not switching and M.state.position ~= 'float' and not api.tree.is_visible() then
    M.switch_position('float')
  end

  M.state.preview_watcher = vim.api.nvim_create_augroup('NvimTreePreview', { clear = true })
  api.tree.open()
end

---Get the buffer number of the preview window
---@return number|nil bufnr The preview buffer number, or nil if not open
function M.preview_buf()
  local manager = require('nvim-tree-preview.manager')
  return manager.instance and manager.instance.preview_buf
end

---Get the window handle of the preview window
---@return number|nil winid The preview window ID, or nil if not open
function M.preview_win()
  local manager = require('nvim-tree-preview.manager')
  return manager.instance and manager.instance.preview_win
end

---Toggle mark on current node and move to next line
---@return nil
function M.mark_and_next()
  local api = require('nvim-tree.api')

  api.marks.toggle()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Down>', true, false, true), 'n', false)
end

---Toggle mark on current node and move to previous line
---@return nil
function M.mark_and_prev()
  local api = require('nvim-tree.api')

  api.marks.toggle()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Up>', true, false, true), 'n', false)
end

---Format the root folder label with icons and path separators
---Replaces home directory with  icon and path separators with .
---@param path string The absolute path to format
---@return string formatted The formatted path with icons
function M.format_root_label(path)
  local home = vim.env.HOME
  local formatted = path

  if home and vim.startswith(path, home) then
    if path == home then
      -- If we're exactly at home, just show the icon
      return ' '
    end
    formatted = '  ' .. path:sub(#home + 2) -- +2 to skip the trailing slash
  else
    -- If outside home, remove leading slash to avoid empty first component
    if vim.startswith(path, '/') then
      formatted = path:sub(2)
    end
  end

  formatted = formatted:gsub('/', ' ')

  return formatted
end

return M
