-- The modules something outside nvim reaches by their path (AGENTS.md, Entry points), checked the
-- way each caller reaches them. lazygit's config.yml sends a `--remote-expr` before each edit
-- command, and one that fails stops the `&&` chain before the file opens. tsave finds a pane's nvim
-- through the pane option publish_tmux_server() sets, asks it for unsaved(), then sends quit()

local t = require('tests.lib.helpers')

-- The dotfiles repo holds this config at nvim/.config/nvim, beside the lazygit and zsh packages
local repo = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_CONFIG))))
)

local TSAVE = 'zsh/.config/zsh/functions/tsave'

-- Called here, these would end the nvim the tests run in
local ENDS_NVIM = { quit = true }

--- @param path string Relative to the repo root
--- @return string
local function read(path)
  return vim.fn.readblob(vim.fs.joinpath(repo, path))
end

--- Every `--remote-expr "<expr>"` a caller's file sends
--- @param path string Relative to the repo root
--- @return string[]
local function remote_exprs(path)
  local exprs = {}
  for expr in read(path):gmatch('%-%-remote%-expr "([^"]+)"') do
    exprs[#exprs + 1] = expr
  end
  t.ok(#exprs > 0, string.format('%s sends no --remote-expr', path))
  return exprs
end

--- Sends expr to this nvim the way an outside client does, and fails unless it evaluates
--- @param expr string
local function evaluates(expr)
  --- @type vim.SystemCompleted?
  local result
  vim.system(
    { vim.v.progpath, '--headless', '--server', vim.v.servername, '--remote-expr', expr },
    { timeout = 5000 },
    function(completed)
      result = completed
    end
  )
  -- Not SystemObj:wait(), which runs only fast events and so never answers the client's request
  t.wait_for(function()
    return result ~= nil
  end, expr, 6000)

  local completed = assert(result)
  t.eq(completed.code, 0, string.format('%s: %s', expr, completed.stderr))
end

t.test("every --remote-expr in lazygit's edit commands evaluates here", function()
  for _, expr in ipairs(remote_exprs('lazygit/.config/lazygit/config.yml')) do
    evaluates(expr)
  end
end)

t.test('every --remote-expr tsave sends evaluates here, or exists if it would quit', function()
  for _, expr in ipairs(remote_exprs(TSAVE)) do
    local path, name = expr:match("^v:lua%.require'([^']+)'%.([%w_]+)%(")
    t.ok(path, string.format('not a v:lua.require call: %s', expr))
    if ENDS_NVIM[name] then
      local module = require(path)
      t.eq(type(module[name]), 'function', expr)
    else
      evaluates(expr)
    end
  end
end)

t.test('tsave reads the pane option publish_tmux_server() sets', function()
  local option = t.ok(read(TSAVE):match('#{(@[%w-]+)}'), 'tsave reads no pane option')
  local utils = require('core.auto-session.utils')

  -- Headless and outside tmux: give it a pane and a UI, and catch its tmux call
  local calls, restore_system = t.spy(vim, 'system', function() end)
  local _, restore_uis = t.spy(vim.api, 'nvim_list_uis', function()
    return { {} }
  end)
  local pane, nvim = vim.env.TMUX_PANE, vim.env.NVIM
  vim.env.TMUX_PANE, vim.env.NVIM = '%1', nil
  utils.publish_tmux_server()
  vim.env.TMUX_PANE, vim.env.NVIM = pane, nvim
  restore_uis()
  restore_system()

  t.eq(#calls, 1, 'tmux calls')
  local cmd = calls[1][1]
  t.ok(vim.tbl_contains(cmd, option), string.format('%s not in %s', option, vim.inspect(cmd)))
end)
