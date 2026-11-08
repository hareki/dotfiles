--- What a test file in tests/ uses: register tests, assert, wait on the event loop, and set up
--- buffers. tests/lib/boot.lua runs the file once the config has booted, VeryLazy included
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

--- Register a test; tests run in order in one nvim process, so each cleans up what it changes
--- @param name string
--- @param fn fun()
function M.test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
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
  vim.wait(ms or 50, function()
    return false
  end)
end

--- Load plugins by their lazy.nvim names and let their scheduled LazyLoad handlers run
--- @param ... string
function M.load(...)
  local lazy = require('lazy')
  lazy.load({ plugins = { ... } })
  M.settle(100)
end

--- Record every call of tbl[key], calling through to the original unless `fake` replaces it
--- @param tbl table
--- @param key string
--- @param fake? function
--- @return table[] calls Each call's arguments, packed with vim.F.pack_len
--- @return fun() restore
function M.spy(tbl, key, fake)
  local original = tbl[key]
  local calls = {}
  tbl[key] = function(...)
    calls[#calls + 1] = vim.F.pack_len(...)
    return (fake or original)(...)
  end
  return calls, function()
    tbl[key] = original
  end
end

--- Open a listed scratch buffer in the current window, so FileType handlers run as for a file
--- @param filetype? string
--- @param lines? string[]
--- @return integer buf
function M.buffer(filetype, lines)
  local buf = vim.api.nvim_create_buf(true, false)
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
  return vim.api.nvim_get_current_buf()
end

--- Run the registered tests, reporting each through `out`; called by boot.lua
--- @param out fun(text: string)
--- @return integer failed
function M._run(out)
  local file = vim.fn.fnamemodify(vim.env.NVIM_TEST_PAYLOAD, ':t:r')
  local failed = 0
  for _, test in ipairs(tests) do
    local ok, err = xpcall(test.fn, debug.traceback)
    if ok then
      out(string.format('ok    %s: %s\n', file, test.name))
    else
      failed = failed + 1
      out(string.format('FAIL  %s: %s\n%s\n', file, test.name, err))
    end
  end
  return failed
end

return M
