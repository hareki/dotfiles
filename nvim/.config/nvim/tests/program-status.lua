-- config/autocmds.lua passing program status (OSC 7501) to the Rex pane, with a real program in a
-- terminal: the query it answers, the reports it forwards, the record it clears for a killed one

local t = require('tests.lib.helpers')

local CLEAR = '\27]7501;state=clear\27\\'

--- @param body string
--- @return string printf A shell command that writes an OSC 7501 sequence
local function osc(body)
  return string.format([[printf '\033]7501;%s\033\\';]], body)
end

--- Run a shell script in a terminal buffer until the test ends
--- @param script string
--- @return integer buf
--- @return integer job
local function run(script)
  local buf = vim.api.nvim_create_buf(false, true)
  local job = vim.api.nvim_buf_call(buf, function()
    return vim.fn.jobstart({ 'sh', '-c', script }, { term = true })
  end)
  t.cleanup(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
  return buf, job
end

--- Wait for a script to end, and for what its end sets off
--- @param job integer
local function ended(job)
  t.wait_for(function()
    return vim.fn.jobwait({ job }, 0)[1] ~= -1
  end, 'the program to end')
  t.settle()
end

--- As inside a Rex pane, recording what is sent to the UI
--- @return table[] calls Each nvim_ui_send call's arguments
local function in_rex()
  t.set(vim.env, 'REX_BLOCK', 'block:test')
  return t.spy(vim.api, 'nvim_ui_send', function() end)
end

--- @param calls table[]
--- @return string[] sequences
local function sent(calls)
  return vim.tbl_map(function(call)
    return call[1]
  end, calls)
end

t.test('a report reaches the pane as the program wrote it', function()
  local calls = in_rex()
  run(osc('state=working:app=claude-code:msg=VGVzdA==') .. ' sleep 30')

  t.wait_for(function()
    return #calls == 1
  end, 'the report')
  t.eq(calls[1][1], '\27]7501;state=working:app=claude-code:msg=VGVzdA==\27\\')
end)

t.test('the query is answered to the program, and the pane hears none of it', function()
  local calls = in_rex()
  -- The program reads the answer off its terminal, as one that asks does: raw, and unechoed
  local heard = vim.fs.joinpath(vim.fn.getcwd(), 'program-status-answer')
  local _, job =
    run(string.format('stty raw -echo; %s dd bs=1 count=10 of=%s 2>/dev/null', osc('?'), heard))
  ended(job)

  t.eq(t.ok(io.open(heard, 'rb'), 'the program read an answer'):read('a'), '\27]7501;?\27\\')
  t.eq(#calls, 0, 'nothing for the pane')
end)

t.test('a program that ends at work has its record cleared', function()
  local calls = in_rex()
  local buf = run(osc('state=working') .. ' sleep 30')
  t.wait_for(function()
    return #calls == 1
  end, 'the report')

  vim.api.nvim_buf_delete(buf, { force = true })
  t.wait_for(function()
    return #calls == 2
  end, 'the clear')
  t.eq(calls[2][1], CLEAR)
end)

t.test('a finished record outlasts its program, and so does a clear of its own', function()
  local calls = in_rex()
  for _, state in ipairs({ 'done', 'error', 'clear' }) do
    local _, job = run(osc('state=working') .. osc('state=' .. state))
    ended(job)
  end

  t.eq(sent(calls), {
    '\27]7501;state=working\27\\',
    '\27]7501;state=done\27\\',
    '\27]7501;state=working\27\\',
    '\27]7501;state=error\27\\',
    '\27]7501;state=working\27\\',
    CLEAR,
  })
end)

t.test('the root record decides the clear, whatever a child record reported last', function()
  local calls = in_rex()
  -- As Claude Code reports a sub-agent: a child record, cleared once the sub-agent ends
  local buf = run(
    osc('state=working')
      .. osc('state=working:id=task')
      .. osc('state=clear:id=task')
      .. ' sleep 30'
  )
  t.wait_for(function()
    return #calls == 3
  end, 'the reports')

  vim.api.nvim_buf_delete(buf, { force = true })
  t.wait_for(function()
    return #calls == 4
  end, 'the clear')
  t.eq(calls[4][1], CLEAR)

  local _, job = run(osc('state=done') .. osc('state=working:id=task'))
  ended(job)
  t.eq(#calls, 6, 'no clear for a finished root record')
end)

t.test('a terminal that reported nothing clears nothing', function()
  local calls = in_rex()
  local _, job = run('true')
  ended(job)

  t.eq(#calls, 0)
end)

t.test('outside a Rex pane the query goes unanswered and nothing is passed on', function()
  t.set(vim.env, 'REX_BLOCK', nil)
  local calls = t.spy(vim.api, 'nvim_ui_send', function() end)
  local answers = t.spy(vim.api, 'nvim_chan_send')
  local _, job = run(osc('?') .. osc('state=working'))
  ended(job)

  t.eq(#calls, 0, 'no report')
  t.eq(#answers, 0, 'no answer')
end)
