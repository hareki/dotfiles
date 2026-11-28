-- core.auto-session.rex-resume: what a report to the Rex pane holds and signs, and when it clears
-- the record instead. Each test runs setup with a token of its own, against the real auto-session

local t = require('tests.lib.helpers')
local auto_session = require('auto-session')
local rex_resume = require('core.auto-session.rex-resume')

local TOKEN = 'test-token-0123456789abcdef'
local GROUP = 'core.auto-session.rex-resume'

--- Run setup as a boot under a Rex pane would, recording what it sends the UI
--- @return table[] calls Each nvim_ui_send call's arguments
local function start()
  t.set(vim.env, 'OSC7577_TOKEN', TOKEN)
  -- auto-session saves nothing in a headless nvim, unless its own tests' switch is on
  t.set(vim.env, 'AUTOSESSION_UNIT_TESTING', '1')
  local calls = t.spy(vim.api, 'nvim_ui_send', function() end)
  rex_resume.setup()
  t.cleanup(function()
    pcall(vim.api.nvim_del_augroup_by_name, GROUP)
  end)
  return calls
end

--- @param event string
local function fire(event)
  vim.api.nvim_exec_autocmds(event, { group = GROUP })
end

--- Split a report into its keys, after checking its framing and its mac
--- @param sequence string
--- @return table<string, string> keys
local function parse(sequence)
  local body, mac = sequence:match('^\27%]7577;(.*):mac=(%x+)\27\\$')
  t.ok(body, 'an OSC 7577 report')
  t.eq(mac, vim.fn.sha256(body .. ':' .. TOKEN), 'the mac signs the body with the token')

  local keys = {}
  for key, value in body:gmatch('(%l+)=([^:]*)') do
    keys[key] = value
  end
  return keys
end

--- @param sequence string
--- @param msg string
local function is_clear(sequence, msg)
  local keys = parse(sequence)
  t.eq(keys.clear, '1', msg)
  t.eq(keys.argv, nil, 'a clear names no command')
  t.eq(tonumber(keys.pid), vim.uv.os_getppid(), "the record cleared is the TUI's")
end

t.test('a bare launch reports `nvim` in its cwd and hides the token', function()
  local calls = start()
  t.eq(vim.env.OSC7577_TOKEN, nil, 'what nvim starts gets no token')

  fire('UIEnter')
  t.eq(#calls, 1, 'one report once the UI is in')
  local keys = parse(calls[1][1])
  t.eq(tonumber(keys.pid), vim.uv.os_getppid(), 'the owner is the parent, the TUI')
  t.ok(math.abs(tonumber(keys.time) - os.time()) <= 5, 'the time is now')
  t.eq(vim.base64.decode(keys.argv), 'nvim')
  t.eq(vim.base64.decode(keys.cwd), vim.fn.getcwd(-1, -1))
end)

t.test('a :cd reports the new cwd', function()
  local calls = start()
  local cwd = vim.fn.getcwd(-1, -1)
  local dir = vim.fs.joinpath(cwd, 'rex-resume-cd')
  vim.fn.mkdir(dir, 'p')
  t.cleanup(function()
    vim.api.nvim_set_current_dir(cwd)
  end)

  vim.api.nvim_set_current_dir(dir)
  t.eq(#calls, 1, 'one report for the change')
  t.eq(vim.base64.decode(parse(calls[1][1]).cwd), vim.fn.getcwd(-1, -1))
end)

t.test('a :cd into a directory auto-session suppresses clears the record', function()
  local calls = start()
  local cwd = vim.fn.getcwd(-1, -1)
  t.cleanup(function()
    vim.api.nvim_set_current_dir(cwd)
  end)

  vim.api.nvim_set_current_dir('/')
  t.eq(#calls, 1, 'one report for the change')
  is_clear(calls[1][1], 'no session is saved for /, so a bare nvim there restores nothing')
end)

t.test('a launch reading stdin clears the record', function()
  local calls = start()
  t.cleanup(function()
    vim.g.in_pager_mode = false
  end)

  vim.api.nvim_exec_autocmds('StdinReadPre', {})
  fire('UIEnter')
  t.eq(#calls, 1)
  is_clear(calls[1][1], 'auto-session saves nothing for a pager')
end)

t.test('a restored session reports', function()
  local calls = start()

  auto_session.run_cmds('post_restore', 'a session')
  t.eq(#calls, 1, 'the spec hooks the report to post_restore_cmds')
  t.eq(vim.base64.decode(parse(calls[1][1]).argv), 'nvim')
end)

t.test('without a token, nothing is set up or sent', function()
  t.set(vim.env, 'OSC7577_TOKEN', nil)
  local calls = t.spy(vim.api, 'nvim_ui_send', function() end)
  rex_resume.setup()
  t.eq(vim.fn.exists('#' .. GROUP), 0, 'no autocmds')

  rex_resume.report()
  t.eq(#calls, 0, 'no report')
end)
