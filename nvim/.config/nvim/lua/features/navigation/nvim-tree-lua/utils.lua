--- @class features.navigation.nvim-tree.utils
local M = {}

--- @alias features.navigation.nvim-tree.utils.Position  'side' | 'float'

--- @class features.navigation.nvim-tree.utils.State
--- @field position features.navigation.nvim-tree.utils.Position
--- @field opts table | nil
--- @field preview_on_focus boolean
--- @field preview_watcher integer | nil

--- @type features.navigation.nvim-tree.utils.State
M.state = {
  position = 'float',
  opts = nil,
  preview_on_focus = false,
  preview_watcher = nil,
}

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

--- @module 'nvim-tree-preview'
local preview = Defer.on_exported_call('nvim-tree-preview')

--- @module 'nvim-tree-preview.manager'
local manager = Defer.on_index('nvim-tree-preview.manager')

--- 'lg' while the float tree shows the preview (wide enough for readable code), else 'vertical_sm'
--- @return 'lg' | 'vertical_sm'
local function compute_size()
  return M.state.preview_on_focus and 'lg' or 'vertical_sm'
end

--- Close the nvim-tree and preview windows, cleaning up watchers
--- @return nil
function M.close_all()
  if M.state.preview_watcher then
    vim.api.nvim_del_augroup_by_id(M.state.preview_watcher)
    M.state.preview_watcher = nil
  end

  preview.unwatch()
  api.tree.close()
end

--- Close the float tree once focus lands in a normal window, like Snacks pickers: floats keep it
--- open, unlike quit_on_focus_loss (any WinLeave), and so does the cmdline window (E11)
--- @return nil
function M.close_on_focus_loss()
  if
    M.state.position ~= 'float'
    or Snacks.util.is_float()
    or vim.fn.getcmdwintype() ~= ''
    or not api.tree.is_visible()
  then
    return
  end

  M.close_all()
end

--- Node action applying `folder_action` to folders; files open or collapse their parent
--- @param folder_action 'expand' | 'collapse' | 'toggle'
--- @return function action
function M.create_node_action(folder_action)
  return function()
    local node = api.tree.get_node_under_cursor()
    if not node then
      return
    end

    --- get_node_under_cursor can return a nvim_tree.api.DirectoryNode, which has `nodes`
    --- @diagnostic disable-next-line: undefined-field
    local is_file_node = node.nodes == nil

    if is_file_node then
      if folder_action == 'collapse' then
        api.node.navigate.parent_close()
        return
      end
      api.node.open.edit()
      if M.state.position == 'float' then
        M.close_all()
      end
      return
    end

    --- get_node_under_cursor can return a nvim_tree.api.DirectoryNode, which has `open`
    --- @diagnostic disable-next-line: undefined-field
    local node_open = node.open

    if
      folder_action == 'toggle'
      or folder_action == 'expand' and not node_open
      or folder_action == 'collapse' and node_open
    then
      api.node.open.edit()
    end
  end
end

--- Switch nvim-tree between float and side panel positions
--- @param position features.navigation.nvim-tree.utils.Position
--- @return nil
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

--- The tree's float geometry: height halved for the preview below, or the whole popup for 'expand'
--- @param action 'expand' | 'collapse'
--- @return utils.ui.layout.WinConfig tree
--- @return integer preview_height Height of the preview below the collapsed tree
function M.float_geometry(action)
  local size = UI.layout.popup(compute_size())
  -- Minus 1 for the space between the two windows
  local collapsed_height = math.floor(size.height / 2) - 1
  -- What the collapsed tree leaves, minus the 2 border rows between the windows
  local preview_height = size.height - collapsed_height - 2

  return {
    width = size.width,
    height = action == 'collapse' and collapsed_height or size.height,
    col = size.col,
    row = size.row,
  },
    preview_height
end

--- Toggle the float tree between half and full height, re-applying the preset's width and position
--- @param action 'expand' | 'collapse'
--- @return nil
function M.toggle_tree_height(action)
  if M.state.position ~= 'float' then
    return
  end

  local tree_win = api.tree.winid()

  if tree_win == nil then
    return
  end

  local cfg = vim.api.nvim_win_get_config(tree_win)
  local geometry = M.float_geometry(action)
  vim.api.nvim_win_set_config(tree_win, vim.tbl_extend('force', cfg, geometry))
end

--- Re-apply the tree geometry to the screen size, tracking resizes like the snacks popups do
--- @return nil
function M.resize()
  if not api.tree.is_visible() then
    return
  end

  if M.state.position == 'float' then
    M.toggle_tree_height(preview.is_open() and 'collapse' or 'expand')
  else
    api.tree.resize()
  end

  -- The preview is positioned relative to the tree, so lay it out once the tree has resized
  preview.resize()
end

--- Toggle the preview, adjusting the float tree's height and the watch state
--- @param force_state boolean | nil Force specific state (true=open, false=close, nil=toggle)
--- @return nil
function M.toggle_preview(force_state)
  local tree_win = api.tree.winid()

  if not tree_win then
    return
  end

  local is_preview_open = preview.is_open()
  local next_open = not is_preview_open

  if force_state ~= nil then
    next_open = force_state
  end

  -- Flip the flag before resizing, so compute_size() picks the target state's size preset
  M.state.preview_on_focus = next_open
  M.toggle_tree_height(next_open and 'collapse' or 'expand')

  if not next_open then
    preview.unwatch()
  elseif not preview.is_open() then
    preview.watch()
  end
end

--- Toggle focus between nvim-tree and preview window
--- @return nil
function M.toggle_focus()
  -- No instance exists until the first preview has been opened
  if not manager.instance then
    return
  end

  manager.instance:toggle_focus()
end

--- Open nvim-tree, back in the float position unless the side tree is already visible
--- @return nil
function M.open()
  if M.state.position ~= 'float' and not api.tree.is_visible() then
    M.switch_position('float')
  end

  -- The preview watcher augroup is created on nvim-tree's TreeAttachedPost event (see the spec)
  api.tree.open()
end

--- Reopen the tree as a side panel
--- @return nil
function M.switch_to_side()
  M.switch_position('side')
  api.tree.open()
end

--- Toggle mark on current node and move to next line
--- @return nil
function M.mark_and_next()
  api.marks.toggle()
  vim.api.nvim_feedkeys(vim.keycode('<Down>'), 'n', false)
end

--- Toggle mark on current node and move to previous line
--- @return nil
function M.mark_and_prev()
  api.marks.toggle()
  vim.api.nvim_feedkeys(vim.keycode('<Up>'), 'n', false)
end

--- Replaces the home directory with its icon and path separators with the collapsed icon
--- @param path string Absolute path
--- @return string formatted
function M.format_root_label(path)
  local home = Conf.icons.file_tree.HOME
  local separator = Conf.icons.file_tree.COLLAPSED .. ' '
  -- Only shortens at a path boundary: /Users/foo2 is not under /Users/foo
  local short = vim.fn.fnamemodify(path, ':~')

  if short == '~' then
    return home
  end

  local formatted
  if vim.startswith(short, '~/') then
    formatted = home .. separator .. short:sub(3)
  else
    -- If outside home, remove leading slash to avoid empty first component
    formatted = short:gsub('^/', '')
  end

  formatted = formatted:gsub('/', separator)

  return formatted
end

return M
