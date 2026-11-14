--- @class features.navigation.nvim-tree-lua.utils
local M = {}

--- @alias features.navigation.nvim-tree-lua.utils.Position  'side' | 'float'

--- @class features.navigation.nvim-tree-lua.utils.State
--- @field position features.navigation.nvim-tree-lua.utils.Position
--- @field opts table | nil The opts setup() was given, re-fed to nvim-tree on a position switch
--- @field preview_on_focus boolean The preview is on; a float tree then keeps the upper half
--- @field preview_watcher integer | nil

--- @type features.navigation.nvim-tree-lua.utils.State
local state = {
  position = 'float',
  opts = nil,
  preview_on_focus = false,
  preview_watcher = nil,
}

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

--- @module 'nvim-tree-preview.manager'
local preview = Defer.on_index('nvim-tree-preview.manager')

--- Close the nvim-tree and preview windows, cleaning up watchers
--- @return nil
function M.close_all()
  if state.preview_watcher then
    vim.api.nvim_del_augroup_by_id(state.preview_watcher)
    state.preview_watcher = nil
  end

  preview.unwatch()
  api.tree.close()
end

--- Close the float tree once focus lands in a normal window, like Snacks pickers: floats keep it
--- open, unlike quit_on_focus_loss (any WinLeave), and so does the cmdline window (E11)
--- @return nil
function M.close_on_focus_loss()
  if
    state.position ~= 'float'
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
      if state.position == 'float' then
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

--- Open the clicked node like `<CR>`, for `<LeftRelease>`: the press already moved the cursor there
--- @return nil
function M.open_clicked_node()
  -- A mapped release never reaches Nvim's own handling, which alone clears its click state: left
  -- stale, the next click's release or drag would start a Visual selection
  vim.api.nvim_feedkeys(vim.keycode('<LeftRelease>'), 'nx', false)

  local mouse = vim.fn.getmousepos()

  -- A press on the border or below the last node still lands the cursor on a node, so test the
  -- mouse's line instead. The cursor's can't tell: a press inside 'scrolloff' scrolls it away
  if vim.fn.screenpos(mouse.winid, mouse.line, 1).row ~= mouse.screenrow then
    return
  end

  M.create_node_action('toggle')()
end

--- Switch nvim-tree between float and side panel positions
--- @param position features.navigation.nvim-tree-lua.utils.Position
--- @return nil
local function switch_position(position)
  if position == state.position then
    return
  end

  state.position = position
  M.close_all()
  -- state.opts is set, since the config runs before any keymap here; nvim-tree supports re-setup:
  -- https://github.com/nvim-tree/nvim-tree.lua/blob/b0b49552c9462900a882fe772993b01d780445fe/lua/nvim-tree.lua#L738
  M.setup(state.opts --[[@as table]])
end

--- The float tree's geometry as the preview choice has it: the whole narrow preset with the preview
--- off, the upper half of a wider one, for readable code below, with it on
--- @return utils.ui.layout.WinConfig tree
--- @return integer preview_height Height of the preview below the tree, with the preview on
function M.float_geometry()
  local size = UI.layout.float(state.preview_on_focus and 'lg' or 'vertical_sm')
  -- Minus 1 for the space between the two windows
  local collapsed_height = math.floor(size.height / 2) - 1
  -- What the collapsed tree leaves, minus the 2 border rows between the windows
  local preview_height = size.height - collapsed_height - 2

  if state.preview_on_focus then
    size.height = collapsed_height
  end

  return size, preview_height
end

--- Give the float tree its geometry, after the preview choice or the screen size changed
--- @return nil
local function reshape()
  if state.position ~= 'float' then
    return
  end

  local tree_win = api.tree.winid()

  if tree_win == nil then
    return
  end

  local cfg = vim.api.nvim_win_get_config(tree_win)
  local geometry = M.float_geometry()
  vim.api.nvim_win_set_config(tree_win, vim.tbl_extend('force', cfg, geometry))
end

--- Re-apply the tree geometry to the screen size, tracking resizes like the Snacks floats do
--- @return nil
function M.resize()
  if not api.tree.is_visible() then
    return
  end

  if state.position == 'float' then
    reshape()
  else
    api.tree.resize()
  end

  -- The preview is positioned relative to the tree, so lay it out once the tree has resized
  preview.resize()
end

--- Start the preview when it is on and not showing, stop it when it is off
--- @return nil
local function sync_preview()
  if not state.preview_on_focus then
    preview.unwatch()
  elseif not preview.is_open() then
    preview.watch()
  end
end

--- Turn the preview on or off; the float tree makes room for it, or takes the room back
--- @param force_state boolean | nil Force specific state (true=open, false=close, nil=toggle)
--- @return nil
function M.toggle_preview(force_state)
  if not api.tree.winid() then
    return
  end

  if force_state == nil then
    state.preview_on_focus = not preview.is_open()
  else
    state.preview_on_focus = force_state
  end

  -- Before the preview opens: it is placed below the tree
  reshape()
  sync_preview()
end

--- Toggle focus between nvim-tree and preview window
--- @return nil
function M.toggle_focus()
  -- No instance exists until the first preview has been opened
  if not preview.instance then
    return
  end

  preview.instance:toggle_focus()
end

--- Open nvim-tree, back in the float position unless the side tree is already visible
--- @return nil
local function open()
  if state.position ~= 'float' and not api.tree.is_visible() then
    switch_position('float')
  end

  -- The spec's TreeAttachedPost subscription starts watch_preview
  api.tree.open()
end

--- Reopen the tree as a side panel
--- @return nil
function M.switch_to_side()
  switch_position('side')
  api.tree.open()
end

--- Open the tree, or close a focused float tree
--- @return nil
function M.toggle()
  if api.tree.is_tree_buf() and state.position == 'float' then
    M.close_all()
    return
  end

  -- No reload: filesystem watchers keep it fresh, a sync reload stalls large repos
  open()
end

--- Set nvim-tree up with `opts`, in the current position; a position switch re-runs it
--- @param opts table nvim-tree's opts, less `view.float.enable`
--- @return nil
function M.setup(opts)
  opts.view.float.enable = state.position == 'float'
  state.opts = opts

  local nvimtree = require('nvim-tree')
  nvimtree.setup(opts)
end

--- Keep the preview following the tree buffer's focus while it is on; one watcher per tree buffer,
--- as nvim-tree wipes it on close
--- @param tree_bufnr integer
--- @return nil
function M.watch_preview(tree_bufnr)
  state.preview_watcher =
    vim.api.nvim_create_augroup('features.navigation.nvim-tree-lua.preview', { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = state.preview_watcher,
    buffer = tree_bufnr,
    callback = sync_preview,
  })
end

--- Where nvim-tree-preview draws, relative to the tree window: below a float tree, beside a side one
--- @return { col: integer, row: integer, width: integer, height: integer } geometry
function M.preview_geometry()
  if state.position ~= 'float' then
    return UI.layout.side_preview()
  end

  local tree, preview_height = M.float_geometry()

  return {
    col = -1,
    row = tree.height + 1,
    width = tree.width,
    height = preview_height,
  }
end

--- Node action toggling the mark on the current node, then moving the cursor with `key`
--- @param key '<Down>' | '<Up>'
--- @return function action
function M.create_mark_action(key)
  return function()
    api.marks.toggle()
    vim.api.nvim_feedkeys(vim.keycode(key), 'n', false)
  end
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

  -- If outside home, remove leading slash to avoid empty first component
  return (short:gsub('^~/', home .. separator):gsub('^/', ''):gsub('/', separator))
end

return M
