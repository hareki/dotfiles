-- features.ai.claudecode-nvim.session: the panel's Claude session travels in the nvim session, and
-- a panel's first start after a restore resumes it; tests/entry-points.lua runs the hook itself

local t = require('tests.lib.helpers')
local auto_session = require('auto-session')
local auto_session_config = require('auto-session.config')
local session = require('features.ai.claudecode-nvim.session')

local ID = '2f713e74-6c61-4eb1-9a81-8b3fa75cc447'
local RESUME = 'claude --resume ' .. ID

--- The stand-in panel's terminal, while one is open
--- @type integer?
local panel

-- The module's state is its own: every test starts and ends with none
local function reset()
  session.forget()
  t.cleanup(session.forget)
end

--- A stand-in panel until the test ends: a terminal claudecode.nvim takes for its own
--- @return integer pid Its job's, as the panel's Claude would report it
local function open_panel()
  local buf = vim.api.nvim_create_buf(false, true)
  local job = vim.api.nvim_buf_call(buf, function()
    return vim.fn.jobstart({ 'sleep', '30' }, { term = true })
  end)
  panel = buf
  t.cleanup(function()
    panel = nil
    vim.fn.jobstop(job)
    -- A restored nvim session has wiped it already
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
  t.set(package.loaded, 'claudecode.terminal', {
    -- A terminal that was wiped is none, as in the plugin
    get_active_terminal_bufnr = function()
      return panel and vim.api.nvim_buf_is_valid(panel) and panel or nil
    end,
  })
  return vim.fn.jobpid(job)
end

--- The user quitting the panel's Claude
local function close_panel()
  panel = nil
end

--- A conversation file, as Claude leaves one once a session got a prompt
--- @return string path
local function transcript()
  return t.write('claude-projects/' .. ID .. '.jsonl', { '{}' })
end

--- What the next nvim gets back: the saved data, handed over as a restore does
--- @param data string?
local function restore(data)
  session.forget()
  if data then
    session.restore('a session', data)
  end
end

t.test('auto-session saves the session with the nvim session and restores it', function()
  reset()
  -- Session files of the test's own, not the user's
  local dir = vim.fs.joinpath(vim.uv.cwd(), 'nvim-sessions')
  t.set(auto_session_config, 'root_dir', dir .. '/')
  t.set(auto_session_config.session_lens.session_control, 'control_dir', dir .. '/control/')

  local pid = open_panel()
  session.report(ID, transcript(), tostring(pid))
  t.ok(auto_session.save_session('with a Claude session'), 'saved')
  session.forget()
  t.ok(auto_session.save_session('without one'), 'saved')

  t.ok(auto_session.restore_session('with a Claude session'), 'restored')
  t.eq(vim.json.decode(t.ok(session.save())).id, ID, 'the session came back')

  t.ok(auto_session.restore_session('without one'), 'restored')
  t.eq(session.save(), nil, 'the restore left none of the session before it')

  t.ok(auto_session.restore_session('with a Claude session'), 'restored')
  t.eq(session.command(), RESUME, 'the restore wiped the panel, and its next start resumes')
end)

t.test('only the Claude of the panel is recorded', function()
  reset()
  t.set(package.loaded, 'claudecode.terminal', nil)
  session.report(ID, transcript(), tostring(vim.uv.os_getpid()))
  t.eq(session.save(), nil, 'no panel yet')

  local pid = open_panel()
  session.report(ID, transcript(), tostring(pid + 1))
  t.eq(session.save(), nil, 'a Claude with another pid')

  -- The hook's expression as tests/entry-points.lua evaluates it, its variables unexpanded
  session.report('$session_id', '$transcript', '$CLAUDE_PID')
  t.eq(session.save(), nil, 'no pid')

  session.report(ID, transcript(), tostring(pid))
  t.eq(vim.json.decode(t.ok(session.save())).id, ID, "the panel's own")
end)

t.test('a restored session is resumed by the first start only', function()
  reset()
  local pid = open_panel()
  session.report(ID, transcript(), tostring(pid))
  close_panel()
  t.eq(session.command(), 'claude', 'a session of this nvim is not one to resume')

  restore(session.save())
  t.eq(session.command(), RESUME, 'the first start')
  t.eq(session.command(), 'claude', 'a start after it is fresh')
  t.eq(vim.json.decode(t.ok(session.save())).id, ID, 'saved again before Claude has reported')
end)

t.test('a toggle of the running panel leaves the restored session to the next start', function()
  reset()
  restore(vim.json.encode({ id = ID, transcript = transcript() }))

  -- A panel that is none of this module's doing: the plugin asks for the command on its toggles too
  open_panel()
  t.eq(session.command(), 'claude', 'a toggle')
  close_panel()
  t.eq(session.command(), RESUME, 'the next start')
end)

t.test('a restored session no panel took is saved again', function()
  reset()
  local pid = open_panel()
  session.report(ID, transcript(), tostring(pid))
  local data = session.save()

  restore(data)
  t.eq(vim.json.decode(t.ok(session.save())).id, ID)
end)

t.test('a /clear moves the panel to the session Claude reports next', function()
  reset()
  local other = '11111111-2222-3333-4444-555555555555'
  restore(vim.json.encode({ id = ID, transcript = transcript() }))
  t.eq(session.command(), RESUME)

  local pid = open_panel()
  session.report(other, transcript(), tostring(pid))
  t.eq(vim.json.decode(t.ok(session.save())).id, other)
end)

t.test('a session that never got a prompt is not resumed', function()
  reset()
  local missing = vim.fs.joinpath(vim.uv.cwd(), 'claude-projects', 'never-written.jsonl')
  restore(vim.json.encode({ id = ID, transcript = missing }))

  t.eq(session.command(), 'claude', 'Claude has no conversation to resume')
  t.eq(session.save(), nil, 'and it is dropped')
end)

t.test('an nvim session without a Claude session leaves none of the one before', function()
  reset()
  local pid = open_panel()
  session.report(ID, transcript(), tostring(pid))

  restore(nil)
  close_panel()
  t.eq(session.save(), nil)
  t.eq(session.command(), 'claude')
end)
