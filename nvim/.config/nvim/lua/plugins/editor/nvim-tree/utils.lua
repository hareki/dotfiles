--- @class nvim-tree.Utils
local M = {}

--- @type nvim-tree.State
M.state = {
  position = 'float',
  opts = nil,
  preview_on_focus = true,
  preview_watcher = nil,
  live_filter_triggered = false,
}

function M.clean_up()
  if M.state.preview_watcher == nil then
    return
  end

  vim.api.nvim_clear_autocmds({ group = M.state.preview_watcher })
  vim.api.nvim_del_augroup_by_id(M.state.preview_watcher)
  M.state.preview_watcher = nil
end

function M.close_all()
  local api = require('nvim-tree.api')
  local preview = require('nvim-tree-preview')

  M.clean_up()

  preview.unwatch()
  api.tree.close()
end

function M.watch()
  local preview = require('nvim-tree-preview')

  if not preview.is_open() then
    preview.watch()
    M.state.preview_on_focus = true
  end
end

function M.unwatch()
  local preview = require('nvim-tree-preview')
  preview.unwatch()
  M.state.preview_on_focus = false
end

---@param folder_action 'expand' | 'collapse' | 'toggle'
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

---@param position nvim-tree.Position
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
  -- nvim-tree explicitly supports subsequent setup calls
  -- https://github.com/nvim-tree/nvim-tree.lua/blob/b0b49552c9462900a882fe772993b01d780445fe/lua/nvim-tree.lua#L738
  nvimtree.setup(M.state.opts)
end

---@param action 'expand' | 'collapse'
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
  local size = ui_utils.popup_config('lg')
  local window_h = math.floor(size.height / 2)
  local half_height = window_h - 1 -- Minus 1 for the space between the two windows

  -- Have to add one extra row if the total height is an odd number to fill out the entire popup size
  local offset = ui_utils.popup_config('lg').height % 2 == 0 and 0 or 1
  local full_height = window_h * 2 + offset

  local cfg = vim.api.nvim_win_get_config(tree_win)

  if action == 'collapse' then
    cfg.height = half_height
  else
    cfg.height = full_height
  end

  vim.api.nvim_win_set_config(tree_win, cfg)
end

---@param force_state boolean|nil
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

function M.toggle_focus()
  local manager = require('nvim-tree-preview.manager')
  manager.instance:toggle_focus()
end

--- @class nvim-tree.OpenParams
--- @field switching boolean|nil

--- @param opts nvim-tree.OpenParams|nil
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

--- @return number|nil
function M.preview_buf()
  local manager = require('nvim-tree-preview.manager')
  return manager.instance and manager.instance.preview_buf
end

--- @return number|nil
function M.preview_win()
  local manager = require('nvim-tree-preview.manager')
  return manager.instance and manager.instance.preview_win
end

return M
