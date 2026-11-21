-- Entry points (docs/architecture.md), each checked the way its caller does: lazygit's edit
-- command, Claude's Stop and SessionStart hooks, NVIM_INTEGRATION

local t = require('tests.lib.helpers')

-- The dotfiles repo holds this config at nvim/.config/nvim, beside lazygit, zsh and claude-code
local repo = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_CONFIG))))
)

local LAZYGIT_EDIT = 'lazygit/.config/lazygit/shell-functions.sh'

-- The $CLAUDE_PID a hook runs with: the pid of its Claude
local CLAUDE_PID = '4242'

-- The files that start nvim with NVIM_INTEGRATION set
local INTEGRATION_CALLERS = {
  'git/.gitconfig',
  LAZYGIT_EDIT,
  'bin/.local/bin/shims/nvim-claude',
}

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
--- @param stdin? string
local function succeeds(cmd, what, env, stdin)
  --- @type vim.SystemCompleted?
  local result
  vim.system(cmd, { env = env, stdin = stdin, timeout = 5000 }, function(completed)
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

--- Check a Claude Code hook: every --remote-expr it sends evaluates here, and run the way Claude
--- runs it, the hook calls `module[name]` here
--- @param hook string Relative to the repo root
--- @param module table
--- @param name string
--- @param payload table What Claude hands the hook on stdin
--- @return table call The arguments of the hook's call, packed with vim.F.pack_len
local function hook_call(hook, module, name, payload)
  for _, expr in ipairs(remote_exprs(hook)) do
    evaluates(expr)
  end

  local calls = t.spy(module, name, function() end)
  succeeds(
    { 'bash', vim.fs.joinpath(repo, hook) },
    hook,
    { NVIM = vim.v.servername, CLAUDE_PID = CLAUDE_PID },
    vim.json.encode(payload)
  )

  -- The hook leaves its request behind in the background
  t.wait_for(function()
    return #calls > 0
  end, "the hook's call")
  return calls[1]
end

t.test("Claude Code's Stop hook reports its finish here", function()
  local hook = 'claude-code/.claude/hooks/nvim-when-done.sh'
  local done = require('features.ai.claudecode-nvim.done')
  -- Nothing in flight, so the done gate lets the hook run on
  local call = hook_call(hook, done, 'mark', { hook_event_name = 'Stop', background_tasks = {} })
  t.eq(call[1], CLAUDE_PID)
end)

t.test("Claude Code's SessionStart hook reports its session here", function()
  local hook = 'claude-code/.claude/hooks/nvim-session-start.sh'
  local session = require('features.ai.claudecode-nvim.session')
  -- A quote in the path needs care on the way into the expr
  local payload = {
    session_id = '2f713e74-6c61-4eb1-9a81-8b3fa75cc447',
    transcript_path = "/tmp/it's a project/2f713e74-6c61-4eb1-9a81-8b3fa75cc447.jsonl",
    hook_event_name = 'SessionStart',
    source = 'startup',
  }
  local call = hook_call(hook, session, 'report', payload)
  t.eq({ call[1], call[2], call[3] }, {
    payload.session_id,
    payload.transcript_path,
    CLAUDE_PID,
  })
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
