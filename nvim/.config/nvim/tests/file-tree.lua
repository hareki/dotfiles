-- features.navigation.nvim-tree-lua.utils: the float tree's shape, reached through its keys. Alone
-- it fills the narrow preset; with the preview on it keeps the upper half of the wide one, the
-- preview below it; the choice outlasts the tree; beside a side tree the preview is a side float

local t = require('tests.lib.helpers')
local tree = require('features.navigation.nvim-tree-lua.utils')

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

--- @module 'nvim-tree-preview.manager'
local preview = Defer.on_index('nvim-tree-preview.manager')

-- Nodes for the tree to list and the preview to show
vim.fn.writefile({ 'one' }, 'a.txt')
vim.fn.writefile({ 'two' }, 'b.txt')

--- @return integer win
local function tree_win()
  return t.ok(api.tree.winid(), 'the tree is closed')
end

--- Press `<leader>e`, typed so that lazy.nvim's stub can load the plugin on the first press
--- @return integer win
local function toggle_tree()
  vim.api.nvim_feedkeys(vim.keycode('<leader>e'), 'mx', false)
  return tree_win()
end

--- Open the tree with `<leader>e`. The preview choice and the position are the module's own, so
--- when the test ends a reopened tree turns the preview off, which also brings the float back
--- @return integer win
local function open_tree()
  t.cleanup(function()
    tree.close_all()
    tree.toggle()
    tree.toggle_preview(false)
    tree.close_all()
  end)
  return toggle_tree()
end

--- Press `lhs` in the tree buffer
--- @param lhs string
local function press(lhs)
  t.map_callback('n', lhs, vim.api.nvim_win_get_buf(tree_win()))()
end

--- Turn the preview on with `B`, the cursor on a file, and wait for it to show
--- @return vim.api.keyset.win_config preview_config
local function preview_on()
  vim.api.nvim_win_set_cursor(tree_win(), { 2, 0 })
  press('B')
  t.wait_for(function()
    return preview.is_open()
  end, 'the preview to open')
  return vim.api.nvim_win_get_config(preview.instance.preview_win)
end

--- @param win integer
--- @return utils.ui.layout.WinConfig
local function geometry(win)
  local config = vim.api.nvim_win_get_config(win)
  return { width = config.width, height = config.height, col = config.col, row = config.row }
end

--- How often the tree window was given a new config since it opened
--- @param configs table[] The calls of nvim_win_set_config
--- @return integer
local function reshapes(configs)
  local win = tree_win()
  return #vim.tbl_filter(function(call)
    return call[1] == win
  end, configs)
end

--- The tree holds the upper part of the wide preset, the preview below it the rest
--- @param preview_config vim.api.keyset.win_config
local function expect_stacked(preview_config)
  local preset = UI.layout.float('lg')
  local win = tree_win()
  local held = geometry(win)

  t.eq(
    { held.width, held.col, held.row },
    { preset.width, preset.col, preset.row },
    "the tree sits at the wide preset's place and width"
  )
  t.ok(held.height < preset.height / 2, 'the tree keeps less than half the height')
  t.eq(
    { preview_config.relative, preview_config.win, preview_config.row },
    { 'win', win, held.height + 1 },
    'the preview starts below the tree'
  )
  t.eq(preview_config.width, preset.width, 'the preview is as wide as the tree')
  t.eq(
    held.height + preview_config.height + 2,
    preset.height,
    'the two windows and the border rows between them fill the preset'
  )
end

t.test('the tree opens as one float filling the narrow preset', function()
  local configs = t.spy(vim.api, 'nvim_win_set_config')
  local win = open_tree()

  t.eq(geometry(win), UI.layout.float('vertical_sm'), 'the tree')
  t.eq(reshapes(configs), 0, 'it was created in that shape, not resized to it')
  t.ok(not preview.is_open(), 'no preview shows')
end)

t.test('with the preview on, the tree keeps the upper half of the wide preset', function()
  open_tree()
  expect_stacked(preview_on())
end)

t.test('turning the preview off gives the tree the narrow preset back', function()
  local win = open_tree()
  preview_on()

  press('B')
  t.ok(not preview.is_open(), 'the preview closed')
  t.eq(geometry(win), UI.layout.float('vertical_sm'), 'the tree')
end)

t.test('the preview choice outlasts the tree, which reopens at half height', function()
  open_tree()
  preview_on()
  press('q')
  t.eq(api.tree.winid(), nil, 'q closes the tree')
  t.ok(not preview.is_open(), 'and the preview with it')

  local configs = t.spy(vim.api, 'nvim_win_set_config')
  toggle_tree()
  t.wait_for(function()
    return preview.is_open()
  end, 'the preview to reopen with the tree')

  expect_stacked(vim.api.nvim_win_get_config(preview.instance.preview_win))
  t.eq(reshapes(configs), 0, 'it was created in that shape, not resized to it')
end)

t.test('a resize keeps the tree and the preview inside the preset', function()
  open_tree()
  preview_on()

  t.set(vim.o, 'lines', 40)
  t.set(vim.o, 'columns', 120)
  vim.api.nvim_exec_autocmds('VimResized', {})

  expect_stacked(vim.api.nvim_win_get_config(preview.instance.preview_win))
end)

t.test('beside a side tree, the preview is the side preview float', function()
  open_tree()
  press('<C-t>')
  local win = tree_win()
  t.eq(vim.api.nvim_win_get_config(win).relative, '', 'the tree is a split')
  t.eq(vim.api.nvim_win_get_width(win), UI.layout.side_panel_width('md'), 'its width')

  local preview_config = preview_on()
  t.eq({
    width = preview_config.width,
    height = preview_config.height,
    row = preview_config.row,
    col = preview_config.col,
  }, UI.layout.side_preview(), 'the preview')
end)
