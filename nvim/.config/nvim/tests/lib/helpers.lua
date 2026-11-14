--- What a test file uses: register tests, assert, wait on the event loop, set up buffers, tabs and
--- floats, look up maps, drive Snacks pickers. tests/lib/boot.lua runs the file after the full
--- boot, VeryLazy too. What a test acquires here (a spy, a buffer, a tab, a float, a picker) is
--- undone when the test ends, pass or fail, so the next one starts clean
--- @class tests.lib.helpers
local M = {}

--- The real vim.lsp.start, which boot.lua replaces with a stub returning nil
--- @type fun(config: vim.lsp.ClientConfig, opts?: table): integer?
M.lsp_start = vim.lsp.start

--- Modules loaded by VimEnter, before VeryLazy: the startup path
--- @type string[]
M.startup_modules = {}

--- @type { name: string, fn: fun() }[]
local tests = {}

--- What the running test undoes when it ends, in the order registered
--- @type fun()[]
local cleanups = {}

--- Register a test; tests run in order in one nvim process
--- @param name string
--- @param fn fun()
function M.test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

--- Run `fn` when the running test ends, pass or fail, after the cleanups registered later than it.
--- For what the helpers below cannot undo: a module's own state, a window, an augroup
--- @param fn fun()
function M.cleanup(fn)
  cleanups[#cleanups + 1] = fn
end

--- Set tbl[key] until the test ends: a module in package.loaded, an environment variable, a field
--- @param tbl table
--- @param key any
--- @param value any
function M.set(tbl, key, value)
  local original = tbl[key]
  tbl[key] = value
  M.cleanup(function()
    tbl[key] = original
  end)
end

--- @param actual any
--- @param expected any
--- @param msg? string
function M.eq(actual, expected, msg)
  if not vim.deep_equal(actual, expected) then
    error(
      string.format(
        '%sexpected %s, got %s',
        msg and (msg .. ': ') or '',
        vim.inspect(expected),
        vim.inspect(actual)
      ),
      2
    )
  end
end

--- @generic T
--- @param value T?
--- @param msg? string
--- @return T value
function M.ok(value, msg)
  if not value then
    error(msg or 'expected a truthy value', 2)
  end
  return value
end

--- Run the event loop (timers, scheduled callbacks, RPC replies) until predicate holds
--- @param predicate fun(): boolean
--- @param msg string What is awaited, for the failure
--- @param timeout_ms? integer Default 2000
function M.wait_for(predicate, msg, timeout_ms)
  if not vim.wait(timeout_ms or 2000, predicate, 10) then
    error('timed out waiting for ' .. msg, 2)
  end
end

--- Run the event loop for a while, letting pending callbacks fire
--- @param ms? integer Default 50
function M.settle(ms)
  vim.wait(ms or 50)
end

--- Record every call of tbl[key] until the test ends, calling through to the original unless
--- `fake` replaces it
--- @param tbl table
--- @param key string
--- @param fake? function
--- @return table[] calls Each call's arguments, packed with vim.F.pack_len
function M.spy(tbl, key, fake)
  local original = tbl[key]
  local calls = {}
  M.set(tbl, key, function(...)
    calls[#calls + 1] = vim.F.pack_len(...)
    return (fake or original)(...)
  end)
  return calls
end

--- Wipe `buf` when the test ends, unless the test already did
--- @param buf integer
local function wipe_after(buf)
  M.cleanup(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

--- Open a listed scratch buffer in the current window, so FileType handlers run as for a file
--- @param filetype? string
--- @param lines? string[]
--- @return integer buf
function M.buffer(filetype, lines)
  local buf = vim.api.nvim_create_buf(true, false)
  wipe_after(buf)
  vim.api.nvim_set_current_buf(buf)
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  if filetype then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

--- Write a file under the boot's cwd (a private temp dir) and edit it, detecting its filetype
--- @param name string
--- @param lines string[]
--- @return integer buf
function M.file(name, lines)
  local path = vim.fs.joinpath(vim.uv.cwd(), name)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  wipe_after(buf)
  return buf
end

--- Open a new tab, closed with its windows when the test ends
--- @return integer tabpage
function M.tab()
  vim.cmd.tabnew()
  local tabpage = vim.api.nvim_get_current_tabpage()
  M.cleanup(function()
    if vim.api.nvim_tabpage_is_valid(tabpage) then
      vim.cmd(string.format('tabclose! %d', vim.api.nvim_tabpage_get_number(tabpage)))
    end
  end)
  return tabpage
end

--- Open a small float on a scratch buffer over the editor, gone with its buffer when the test ends
--- @param enter? boolean Focus it; by default the current window stays current
--- @return integer win
--- @return integer buf
function M.float(enter)
  local buf = vim.api.nvim_create_buf(false, true)
  wipe_after(buf)
  local win = vim.api.nvim_open_win(buf, enter == true, {
    relative = 'editor',
    row = 1,
    col = 1,
    width = 10,
    height = 1,
  })
  return win, buf
end

--- The map on lhs: `buf`'s own when given, else the global one
--- @param mode string
--- @param lhs string In any notation keycode() reads (`<leader>F`, `<Tab>`)
--- @param buf? integer
--- @return table? map A dict from nvim_get_keymap() or nvim_buf_get_keymap(), nil when unmapped
function M.keymap(mode, lhs, buf)
  -- Compared as keytrans() text: lhsraw keeps keys like <C-S> unsimplified
  local wanted = vim.fn.keytrans(vim.keycode(lhs))
  local maps = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
  for _, map in ipairs(maps) do
    if vim.fn.keytrans(map.lhsraw) == wanted then
      return map
    end
  end
end

--- The callback of the map on lhs (see keymap()), failing the test when there is none
--- @param mode string
--- @param lhs string
--- @param buf? integer
--- @return function
function M.map_callback(mode, lhs, buf)
  local where = buf and string.format('buffer %d', buf) or 'the global maps'
  local map =
    M.ok(M.keymap(mode, lhs, buf), string.format('no %s map on %s in %s', mode, lhs, where))
  return M.ok(map.callback, string.format('%s maps no callback', lhs))
end

--- Close a Snacks picker and wait for the teardown snacks schedules
--- @param picker snacks.Picker
function M.close_picker(picker)
  picker:close()
  M.wait_for(function()
    return picker.preview == nil
  end, 'the picker teardown')
end

--- The open picker of `source`, once it shows and `ready` holds; closed when the test ends
--- @param source string
--- @param ready? fun(picker: snacks.Picker): boolean Default: it lists an item
--- @param msg? string What is awaited, for the failure
--- @return snacks.Picker
function M.await_picker(source, ready, msg)
  ready = ready or function(picker)
    return #picker:items() > 0
  end

  local picker --- @type snacks.Picker?
  M.wait_for(function()
    picker = Snacks.picker.get({ source = source })[1]
    return picker ~= nil and picker.shown == true and ready(picker)
  end, msg or string.format('the %s picker to list its items', source))
  --- @cast picker snacks.Picker
  M.cleanup(function()
    if not picker.closed then
      M.close_picker(picker)
    end
  end)
  return picker
end

--- Run `open`, then wait for the picker of `source` it opens (see await_picker())
--- @param open fun()
--- @param source string
--- @param ready? fun(picker: snacks.Picker): boolean
--- @param msg? string
--- @return snacks.Picker
function M.open_picker(open, source, ready, msg)
  open()
  return M.await_picker(source, ready, msg)
end

--- Run the cleanups the test that just ended registered, newest first, each one whatever the
--- others did; one may register more (a module reset that opens a window)
--- @return string[] errors
local function unwind()
  local errors = {}
  while #cleanups > 0 do
    local ok, err = xpcall(table.remove(cleanups), debug.traceback)
    if not ok then
      errors[#errors + 1] = 'cleanup: ' .. err
    end
  end
  return errors
end

--- Run the registered tests, reporting each through `out`; called by boot.lua
--- @param out fun(text: string)
--- @return integer failed
function M._run(out)
  local file = vim.fn.fnamemodify(vim.env.NVIM_TEST_PAYLOAD, ':t:r')
  local failed = 0
  for _, test in ipairs(tests) do
    local ok, err = xpcall(test.fn, debug.traceback)
    local errors = unwind()
    if not ok then
      table.insert(errors, 1, err)
    end

    if #errors == 0 then
      out(string.format('ok    %s: %s\n', file, test.name))
    else
      failed = failed + 1
      out(string.format('FAIL  %s: %s\n%s\n', file, test.name, table.concat(errors, '\n')))
    end
  end
  return failed
end

return M
