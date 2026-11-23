-- features.preview.live-preview-nvim: `<leader>pp` in the tree previews the node under the cursor,
-- and the port a preview starts on, with the plugin's lsof check answered by a stub

local t = require('tests.lib.helpers')
local tree = require('features.navigation.nvim-tree-lua.utils')

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

-- The plugin's default, which the spec's opts keep
local CONFIGURED_PORT = 5500

-- A space in the name, a file it can't preview, and a folder named like one it can, and a link to it
vim.fn.writefile({ '# Notes' }, 'my notes.md')
vim.fn.writefile({ 'plain' }, 'plain.txt')
vim.fn.mkdir('docs.md', 'p')
assert(vim.uv.fs_symlink('docs.md', 'linked.md'))

--- Answer the plugin's lsof check (livepreview.utils.processes_listening_on_port) until the test
--- ends, as if a process listened on the ports `taken` holds; every other command runs
--- @param taken fun(port: integer): boolean
--- @return integer[] checked The ports checked, in order
local function stub_ports(taken)
  local system = vim.system
  local checked = {}
  t.set(vim, 'system', function(cmd, ...)
    local port = tonumber(cmd[3] and cmd[3]:match('^lsof %-i:(%d+) ') or nil)
    if not port then
      return system(cmd, ...)
    end

    checked[#checked + 1] = port
    -- What the check's `lsof | grep LISTEN | awk` pipeline prints: a name and a pid per listener
    local stdout = taken(port) and string.format('node %d\n', 40000 + #checked) or ''
    return {
      wait = function()
        return { code = 0, signal = 0, stdout = stdout, stderr = '' }
      end,
    }
  end)
  return checked
end

--- @return boolean
local function none_taken()
  return false
end

--- Stub :LivePreview until the test ends, recording each start's arguments and the port it binds
--- @return { args: string[], port: integer }[] starts
local function stub_start()
  local starts = {}
  t.set(vim.cmd, 'LivePreview', function(command)
    local livepreview_config = require('livepreview.config')
    starts[#starts + 1] = { args = command.args, port = livepreview_config.config.port }
  end)
  return starts
end

--- Open the tree with `<leader>e`
--- @return integer win
local function open_tree()
  t.cleanup(tree.close_all)
  t.press('<leader>e')
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

--- Press `<leader>pp` on the node for `name`, with the server, its ports and the warning stubbed
--- @param name string
--- @return { args: string[], port: integer }[] starts
--- @return table[] warnings The calls of Notifier.warn
local function preview(name)
  stub_ports(none_taken)
  local starts = stub_start()
  local warnings = t.spy(Notifier, 'warn', function() end)

  cursor_on(open_tree(), name)
  t.press('<leader>pp')
  return starts, warnings
end

--- Press `<leader>pp` in a Markdown file, with the server stubbed and the ports `taken` holds
--- taken; the plugin's config is restored when the test ends, since each start rewrites its port
--- @param taken fun(port: integer): boolean
--- @return { args: string[], port: integer }[] starts
--- @return integer[] checked The ports checked, in order
local function start_in_file(taken)
  local livepreview_config = require('livepreview.config')
  t.set(livepreview_config, 'config', livepreview_config.config)
  local checked = stub_ports(taken)
  local starts = stub_start()

  t.file('page.md', { '# Page' })
  t.press('<leader>pp')
  t.eq(#starts, 1, 'one start')
  return starts, checked
end

t.test('a previewable file starts the preview of its path', function()
  local starts, warnings = preview('my notes.md')

  t.eq(#warnings, 0, 'no warning')
  t.eq(
    starts[1] and starts[1].args,
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

t.test('a link to a folder warns too', function()
  local starts, warnings = preview('linked.md')

  t.eq(#starts, 0, 'no start')
  t.eq(#warnings, 1, 'one warning')
end)

t.test('the preview starts on the configured port while nothing listens there', function()
  local starts, checked = start_in_file(none_taken)

  t.eq(starts[1].port, CONFIGURED_PORT, 'the port')
  t.eq(checked, { CONFIGURED_PORT }, 'only that port is checked')
end)

t.test('a taken port moves the preview to the first free port above it', function()
  local starts, checked = start_in_file(function(port)
    return port < CONFIGURED_PORT + 2
  end)

  t.eq(starts[1].port, CONFIGURED_PORT + 2, 'the port')
  t.eq(
    checked,
    { CONFIGURED_PORT, CONFIGURED_PORT + 1, CONFIGURED_PORT + 2 },
    'each port up to it is checked'
  )
end)

t.test('with every port above it taken, the preview keeps the configured port', function()
  local starts, checked = start_in_file(function()
    return true
  end)

  t.eq(starts[1].port, CONFIGURED_PORT, 'the port')
  t.eq(#checked, 65535 - CONFIGURED_PORT + 1, 'every port up to 65535 is checked')
end)

t.test('a running server keeps its port, with no check', function()
  local livepreview = require('livepreview')
  -- A server listening on another port than the configured one, as start() asks its socket
  t.set(livepreview, 'serverObj', {
    server = {
      getsockname = function()
        return { port = CONFIGURED_PORT + 7 }
      end,
    },
  })
  local starts, checked = start_in_file(none_taken)

  t.eq(starts[1].port, CONFIGURED_PORT + 7, "the running server's port")
  t.eq(checked, {}, 'no port is checked')
end)
