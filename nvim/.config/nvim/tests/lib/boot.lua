-- One headless boot for tests/run.sh and tests/ab.sh (see tests/lib/env.sh), run from `-c` before
-- VimEnter: finish the startup a UI session gets, run $NVIM_TEST_PAYLOAD, exit with its status

local source = debug.getinfo(1, 'S').source:sub(2)
-- The config holding this harness, which for ab.sh's HEAD copy is not the config under test
local harness_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
package.path = harness_root .. '/?.lua;' .. package.path

local helpers = require('tests.lib.helpers')

--- @param text string
local function out(text)
  io.stdout:write(text)
  io.stdout:flush()
end

--- @return integer? client_id
local function start_no_server()
  return nil
end

local function main()
  -- Kept off: os.exit skips VimLeavePre, so a started server would outlive the boot
  helpers.lsp_start = vim.lsp.start
  vim.lsp.start = start_no_server

  -- Headless nvim fires no UIEnter, so lazy.nvim never fires VeryLazy (config.keymaps, ...)
  vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy', modeline = false })
  -- Until nvim-lspconfig's deferred enable has run (75 ms, after lazy.nvim's scheduled LazyLoad);
  -- the cap covers a revision that never enables lua_ls
  vim.wait(300, function()
    return vim.lsp.is_enabled('lua_ls')
  end, 10)

  local payload = assert(vim.env.NVIM_TEST_PAYLOAD, 'NVIM_TEST_PAYLOAD is unset')
  local ok, err = xpcall(dofile, debug.traceback, payload)
  if not ok then
    out(string.format('ERROR %s\n%s\n', payload, err))
    os.exit(2)
  end

  local failed = helpers._run(out)
  os.exit(failed > 0 and 1 or 0)
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    helpers.startup_modules = vim.tbl_keys(package.loaded)
    vim.schedule(main)
  end,
})
