-- The resume reports nvim sends a Rex pane (core/auto-session/rex-resume.lua): what a report holds
-- and signs, and which launches send one. Each test runs setup again with a token of its own, as
-- the boot under a Rex pane does, and reads the reports off nvim_ui_send

local t = require('tests.lib.helpers')
local rex_resume = require('core.auto-session.rex-resume')

local TOKEN = 'test-token-0123456789abcdef'
local GROUP = 'core.auto-session.rex-resume'

--- Run setup as a boot under a Rex pane would, recording what it sends the UI
--- @return table[] calls Each nvim_ui_send call's arguments
local function start()
  t.set(vim.env, 'OSC7577_TOKEN', TOKEN)
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

t.test('a launch on one directory reports as a bare one does', function()
  local dir = vim.fs.joinpath(vim.fn.getcwd(-1, -1), 'rex-resume-dir')
  vim.fn.mkdir(dir, 'p')
  vim.cmd.argadd(vim.fn.fnameescape(dir))
  t.cleanup(function()
    vim.cmd('%argdelete')
  end)
  local calls = start()

  fire('UIEnter')
  t.eq(#calls, 1, 'auto-session restores in a lone directory too')
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

t.test('a launch on files reports nothing until a session loads', function()
  t.write('rex-resume.txt', { 'text' })
  vim.cmd.argadd('rex-resume.txt')
  t.cleanup(function()
    vim.cmd('%argdelete')
  end)
  local calls = start()

  fire('UIEnter')
  t.eq(#calls, 0, 'no report for a launch on files')
  fire('SessionLoadPost')
  t.eq(#calls, 1, 'a loaded session reports')
end)

t.test('a launch reading stdin reports nothing', function()
  local calls = start()

  fire('StdinReadPre')
  fire('UIEnter')
  t.eq(#calls, 0)
end)

t.test('without a token, setup sets up nothing', function()
  t.set(vim.env, 'OSC7577_TOKEN', nil)
  rex_resume.setup()
  t.eq(vim.fn.exists('#' .. GROUP), 0, 'no autocmds')
end)
