-- features.preview.live-preview-nvim: `<leader>pp` in the tree previews the node under the cursor

local t = require('tests.lib.helpers')
local tree = require('features.navigation.nvim-tree-lua.utils')

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

-- A space in the name, a file it can't preview, and a folder named like one it can
vim.fn.writefile({ '# Notes' }, 'my notes.md')
vim.fn.writefile({ 'plain' }, 'plain.txt')
vim.fn.mkdir('docs.md', 'p')

--- Open the tree with `<leader>e`, typed so that lazy.nvim's stub can load the plugin
--- @return integer win
local function open_tree()
  t.cleanup(tree.close_all)
  vim.api.nvim_feedkeys(vim.keycode('<leader>e'), 'mx', false)
  return t.ok(api.tree.winid(), 'the tree is closed')
end

--- Put the tree's cursor on the node for `name`, under the cwd
--- @param win integer
--- @param name string
local function cursor_on(win, name)
  local path = vim.fs.joinpath(vim.uv.cwd(), name)
  for row = 1, vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)) do
    vim.api.nvim_win_set_cursor(win, { row, 0 })
    local node = api.tree.get_node_under_cursor()
    if node and node.absolute_path == path then
      return
    end
  end
  error('no node for ' .. name)
end

--- Press `<leader>pp` on the node for `name`, with the server and the warning stubbed
--- @param name string
--- @return table[] starts The calls of :LivePreview
--- @return table[] warnings The calls of Notifier.warn
local function preview(name)
  local starts = t.spy(vim.cmd, 'LivePreview', function() end)
  local warnings = t.spy(Notifier, 'warn', function() end)

  cursor_on(open_tree(), name)
  vim.api.nvim_feedkeys(vim.keycode('<leader>pp'), 'mx', false)
  return starts, warnings
end

t.test('a previewable file starts the preview of its path', function()
  local starts, warnings = preview('my notes.md')

  t.eq(#warnings, 0, 'no warning')
  t.eq(
    starts[1] and starts[1][1].args,
    { 'start', vim.fs.joinpath(vim.uv.cwd(), 'my notes.md') },
    'the start command, its path one argument'
  )
end)

t.test('a file it cannot preview warns instead', function()
  local starts, warnings = preview('plain.txt')

  t.eq(#starts, 0, 'no start')
  t.eq(#warnings, 1, 'one warning')
end)

t.test('a folder warns instead, whatever its name ends in', function()
  local starts, warnings = preview('docs.md')

  t.eq(#starts, 0, 'no start')
  t.eq(#warnings, 1, 'one warning')
end)
