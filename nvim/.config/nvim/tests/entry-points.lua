-- The modules something outside nvim reaches by their path (AGENTS.md, Entry points), each checked
-- the way its caller does: lazygit's edit command, tsave, Claude's Stop hook, NVIM_INTEGRATION

local t = require('tests.lib.helpers')

-- The dotfiles repo holds this config at nvim/.config/nvim, beside lazygit, zsh and claude-code
local repo = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_CONFIG))))
)

local TSAVE = 'zsh/.config/zsh/functions/tsave'
local LAZYGIT_EDIT = 'lazygit/.config/lazygit/shell-functions.sh'

-- The files that start nvim with NVIM_INTEGRATION set
local INTEGRATION_CALLERS = {
  'git/.gitconfig',
  LAZYGIT_EDIT,
  'bin/.local/bin/shims/nvim-claude',
}

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

--- Run cmd to its end while this nvim keeps answering the requests it sends here, and fail unless
--- it exits 0. Not SystemObj:wait(), which runs only fast events and so never answers one
--- @param cmd string[]
--- @param what string Names the command in a failure
--- @param env? table<string, string>
local function succeeds(cmd, what, env)
  --- @type vim.SystemCompleted?
  local result
  vim.system(cmd, { env = env, timeout = 5000 }, function(completed)
    result = completed
  end)
  t.wait_for(function()
    return result ~= nil
  end, what, 6000)

  local completed = assert(result)
  t.eq(completed.code, 0, string.format('%s: %s', what, completed.stderr))
end

--- Sends expr to this nvim the way an outside client does, and fails unless it evaluates
--- @param expr string
local function evaluates(expr)
  succeeds(
    { vim.v.progpath, '--headless', '--server', vim.v.servername, '--remote-expr', expr },
    expr
  )
end

t.test("lazygit's edit command opens its files in this nvim, on the line it names", function()
  local lines = {}
  for i = 1, 20 do
    lines[i] = 'line ' .. i
  end
  -- Names that need care on the way: a quote for the expr, brackets and spaces for `:drop`
  local path = vim.fs.joinpath(vim.uv.cwd(), "edited from lazygit's view.txt")
  local other = vim.fs.joinpath(vim.uv.cwd(), 'another [one].txt')
  for _, file in ipairs({ path, other }) do
    vim.fn.writefile(lines, file)
  end
  t.cleanup(function()
    for _, file in ipairs({ path, other }) do
      -- bufadd() finds the file's buffer, or makes one when the edit never opened it
      vim.api.nvim_buf_delete(vim.fn.bufadd(file), { force = true })
    end
  end)

  --- Run an edit command as lazygit does, its functions file sourced into a shell inside this nvim
  --- @param shell string[]
  --- @param command string
  local function lazygit_runs(shell, command)
    local script = string.format('source %s\n%s', vim.fs.joinpath(repo, LAZYGIT_EDIT), command)
    succeeds(
      vim.list_extend(vim.deepcopy(shell), { script }),
      string.format('%s: %s', shell[1], command),
      { NVIM = vim.v.servername }
    )
  end

  -- lazygit quotes every path it hands over. The user's shell, and the one a plain `sh` would be
  local quoted, quoted_other = vim.fn.shellescape(path), vim.fn.shellescape(other)
  for _, shell in ipairs({ { '/bin/zsh', '-f', '-c' }, { '/bin/sh', '-c' } }) do
    vim.cmd.enew()
    lazygit_runs(shell, string.format('lazygit_edit %s %s', quoted_other, quoted))
    t.eq(vim.api.nvim_buf_get_name(0), other, shell[1] .. ': the current file of two')
    t.eq(vim.fn.buflisted(path), 1, shell[1] .. ': the second file is listed')

    lazygit_runs(shell, string.format('lazygit_edit +7 %s', quoted))
    t.eq(vim.api.nvim_buf_get_name(0), path, shell[1] .. ': the current file')
    t.eq(vim.api.nvim_win_get_cursor(0)[1], 7, shell[1] .. ': the line')
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

t.test("the --remote-expr Claude Code's Stop hook sends evaluates here", function()
  for _, expr in ipairs(remote_exprs('claude-code/.claude/hooks/nvim-when-done.sh')) do
    evaluates(expr)
  end
end)

--- Boot a child nvim on this config the way a tool with that NVIM_INTEGRATION starts it
--- @param integration string
--- @return string statusline Its 'statusline' option once the config has loaded
--- @return string stderr
local function boot_as(integration)
  local print_statusline = 'lua io.stdout:write(vim.o.statusline) os.exit(0)'
  local result = vim
    .system(
      { vim.v.progpath, '--headless', '-i', 'NONE', '-c', print_statusline },
      { env = { NVIM_INTEGRATION = integration }, timeout = 30000 }
    )
    :wait()
  t.eq(result.code, 0, string.format('NVIM_INTEGRATION=%s: %s', integration, result.stderr))
  return result.stdout, result.stderr
end

t.test("every NVIM_INTEGRATION a tool sets boots nvim into that host's label", function()
  local booted = {}
  for _, path in ipairs(INTEGRATION_CALLERS) do
    local sets = false
    for integration in read(path):gmatch('NVIM_INTEGRATION=([%w-]+)') do
      sets = true
      if not booted[integration] then
        booted[integration] = true
        local statusline, stderr = boot_as(integration)
        t.ok(
          statusline:find('%#StatusLineIntegration#', 1, true),
          string.format('%s sets %s: %q %s', path, integration, statusline, stderr)
        )
      end
    end
    t.ok(sets, path .. ' sets no NVIM_INTEGRATION')
  end
end)

t.test('an NVIM_INTEGRATION no host answers to aborts the boot, naming the ones that do', function()
  local statusline, stderr = boot_as('no-such-tool')
  t.ok(stderr:find('Invalid NVIM_INTEGRATION "no-such-tool"', 1, true), stderr)
  t.ok(stderr:find('claude-code, git, lazygit', 1, true), stderr)
  t.ok(not statusline:find('StatusLineIntegration', 1, true), 'no host label shows')
end)

t.test('tsave reads the pane option publish_tmux_server() sets', function()
  local option = t.ok(read(TSAVE):match('#{(@[%w-]+)}'), 'tsave reads no pane option')
  local tsave = require('core.auto-session.tsave')

  -- Headless and outside tmux: give it a pane and a UI, and catch its tmux call
  local calls = t.spy(vim, 'system', function() end)
  t.spy(vim.api, 'nvim_list_uis', function()
    return { {} }
  end)
  t.set(vim.env, 'TMUX_PANE', '%1')
  tsave.publish_tmux_server()

  t.eq(#calls, 1, 'tmux calls')
  local cmd = calls[1][1]
  t.ok(vim.tbl_contains(cmd, option), string.format('%s not in %s', option, vim.inspect(cmd)))
end)
