-- The save pipeline (features.formatting.conform-nvim.style-enforcers): its lazy-loading keys, the
-- runner, driven through its `steps`/`timeout_ms` seam, real steps on stylua and in-process LSPs

local t = require('tests.lib.helpers')
local style_enforcers = require('features.formatting.conform-nvim.style-enforcers')

local conform_step = require('features.formatting.conform-nvim.style-enforcers.conform-nvim')
local eslint = require('features.formatting.conform-nvim.style-enforcers.eslint')
local oxfmt = require('features.formatting.conform-nvim.style-enforcers.oxfmt')
local oxlint = require('features.formatting.conform-nvim.style-enforcers.oxlint')

local levels = vim.log.levels

local UNFORMATTED = { 'local   x =1' }
local FORMATTED = { 'local x = 1' }

local SERVER_CAPABILITIES = {
  textDocumentSync = 1,
  documentFormattingProvider = true,
  executeCommandProvider = { commands = { 'eslint.applyAllFixes', 'oxc.fixAll' } },
}

--- @param buf integer
--- @return string[]
local function buf_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

--- @param buf integer
--- @return string[]
local function file_lines(buf)
  return vim.fn.readfile(vim.api.nvim_buf_get_name(buf))
end

--- A file buffer with unsaved changes
--- @param name string
--- @return integer buf
local function modified_file(name)
  local buf = t.file(name, { 'saved' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'edited' })
  return buf
end

--- Record the notices, through vim.notify
--- @return { level: integer, title?: string, msg: string }[] notices
--- @return fun() restore
local function record_notices()
  local notices = {}
  local _, restore = t.spy(vim, 'notify', function(msg, level, opts)
    notices[#notices + 1] = { level = level, title = opts and opts.title, msg = msg }
  end)
  return notices, restore
end

--- Replace the progress handles with recorders
--- @return table[] events `{ 'start', title }`, `{ 'report', title, percentage }` or `{ 'finish' }`
--- @return table[] creates The arguments of each utils.progress.create call
--- @return fun() restore
local function record_progress()
  local progress_utils = require('utils.progress')
  local events = {}
  local creates, restore = t.spy(progress_utils, 'create', function()
    return {
      start = function(_, title)
        events[#events + 1] = { 'start', title }
      end,
      report = function(_, title, percentage)
        events[#events + 1] = { 'report', title, percentage }
      end,
      finish = function()
        events[#events + 1] = { 'finish' }
      end,
    }
  end)
  return events, creates, restore
end

--- A scripted step for every buffer: logs its name to trace, then runs script (default: done)
--- @param name string
--- @param trace string[]
--- @param script? fun(ctx: features.formatting.conform-nvim.style-enforcers.Context)
--- @return features.formatting.conform-nvim.style-enforcers.Step
local function step(name, trace, script)
  return {
    name = name,
    label = 'Running ' .. name,
    kind = 'fix',
    applies = function()
      return true
    end,
    run = function(ctx)
      trace[#trace + 1] = name
      if script then
        script(ctx)
      else
        ctx.done()
      end
    end,
    failure = function(err, debug)
      return debug and err or name
    end,
  }
end

--- Run the pipeline and wait for its end
--- @param opts features.formatting.conform-nvim.style-enforcers.RunOpts
--- @return boolean ok
local function run(opts)
  local result
  style_enforcers.run(vim.tbl_extend('force', opts, {
    on_done = function(ok)
      result = ok
    end,
  }))
  t.wait_for(function()
    return result ~= nil
  end, 'the end of the run')
  return result
end

--- Start an in-process language server attached to buf; each request it gets is logged, then
--- answered by handlers[method](params, reply), or at once with a null result
--- @param buf integer
--- @param name string
--- @param handlers table<string, fun(params: table, reply: fun(err?: table, result?: any))>
--- @return { method: string, params: table }[] log
--- @return fun() stop
local function serve(buf, name, handlers)
  local log = {}

  local function cmd(dispatchers)
    local closing = false
    local next_id = 0
    return {
      request = function(method, params, callback, notify_reply)
        next_id = next_id + 1
        local id = next_id
        local function reply(err, result)
          if notify_reply then
            notify_reply(id)
          end
          callback(err, result)
        end

        if method == 'initialize' then
          reply(nil, { capabilities = SERVER_CAPABILITIES })
        elseif method == 'shutdown' then
          reply(nil, nil)
        else
          log[#log + 1] = { method = method, params = params }
          local handler = handlers[method]
          if handler then
            handler(params, reply)
          else
            reply(nil, nil)
          end
        end
        return true, id
      end,
      notify = function(method)
        if method == 'exit' then
          dispatchers.on_exit(0, 15)
        end
        return true
      end,
      is_closing = function()
        return closing
      end,
      terminate = function()
        closing = true
      end,
    }
  end

  local id = t.ok(t.lsp_start({ name = name, cmd = cmd, root_dir = vim.uv.cwd() }, {
    bufnr = buf,
    -- A client left over by a failed test must not serve this one
    reuse_client = function()
      return false
    end,
  }))
  t.wait_for(function()
    return #vim.lsp.get_clients({ id = id, bufnr = buf }) > 0
  end, name .. ' attaching')

  return log,
    function()
      local client = vim.lsp.get_client_by_id(id)
      if client then
        client:stop()
        t.wait_for(function()
          return vim.lsp.get_client_by_id(id) == nil
        end, name .. ' stopping')
      end
    end
end

--- @param log { method: string }[]
--- @return string[]
local function methods(log)
  return vim.tbl_map(function(entry)
    return entry.method
  end, log)
end

-- Keys

t.test('<A-s> loads conform.nvim on the first press, then formats and saves', function()
  t.eq(package.loaded['conform'], nil, 'conform.nvim loaded before the first press')
  -- conform.nvim defines it as it loads; until then lazy.nvim's stub stands in
  t.eq(vim.fn.exists(':ConformInfo'), 2, ':ConformInfo before the first save')
  local buf = t.file('first.lua', UNFORMATTED)
  vim.bo[buf].modified = true

  -- lazy.nvim's stub loads the plugin and replays the key into the typeahead, which 'x' drains
  vim.api.nvim_feedkeys(vim.keycode('<A-s>'), 'mx', false)
  t.wait_for(function()
    return not vim.bo[buf].modified
  end, 'the write')

  t.eq(file_lines(buf), FORMATTED, 'the file on disk')
  t.eq(vim.fn.exists(':ConformInfo'), 2, ':ConformInfo after the first save')
  vim.cmd.bwipeout()
end)

t.test('<leader>F formats without saving', function()
  local buf = t.file('no-save.lua', UNFORMATTED)

  t.map_callback('n', '<leader>F')()
  t.wait_for(function()
    return vim.deep_equal(buf_lines(buf), FORMATTED)
  end, 'the format')
  t.settle(100)

  t.ok(vim.bo[buf].modified, 'the buffer was written')
  t.eq(file_lines(buf), UNFORMATTED, 'the file on disk')
  vim.cmd.bwipeout({ bang = true })
end)

t.test('<F40> formats and saves every modified buffer', function()
  local notices, restore = record_notices()
  local first = t.file('all-1.lua', UNFORMATTED)
  vim.bo[first].modified = true
  local second = t.file('all-2.lua', UNFORMATTED)
  vim.bo[second].modified = true

  t.map_callback('n', '<F40>')()
  t.wait_for(function()
    return #notices > 0
  end, 'the summary')
  restore()

  t.eq(file_lines(first), FORMATTED, 'the first file')
  t.eq(file_lines(second), FORMATTED, 'the second file')
  t.eq(notices[1].level, levels.INFO, 'the summary level')
  vim.cmd('bwipeout ' .. first .. ' ' .. second)
end)

-- The runner

t.test('runs the steps that apply in order, counting progress over them', function()
  local events, creates, restore = record_progress()
  local trace = {}
  local skipped = step('skipped', trace)
  skipped.applies = function()
    return false
  end
  local buf = modified_file('order.txt')

  local ok = run({ buf = buf, steps = { step('first', trace), skipped, step('second', trace) } })
  restore()

  t.eq(ok, true, 'the run result')
  t.eq(trace, { 'first', 'second' }, 'the steps run')
  t.eq(events, {
    { 'start', 'Running first' },
    { 'report', 'Running second', 50 },
    { 'finish' },
  }, 'the progress')
  t.eq(
    { creates[1][1].bufnr, creates[1][1].client_name, creates[1][1].pending_ms },
    { buf, 'stenfo', 500 },
    'the progress handle'
  )
  t.eq(file_lines(buf), { 'edited' }, 'the file on disk')
  vim.cmd.bwipeout()
end)

t.test('a failed step ends the run with its one notice, keeping what ran before', function()
  local notices, restore = record_notices()
  local trace = {}
  local buf = modified_file('fail.txt')

  local ok = run({
    buf = buf,
    debug = true,
    steps = {
      step('edit', trace, function(ctx)
        vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, { 'fixed' })
        ctx.done()
      end),
      step('broken', trace, function(ctx)
        vim.defer_fn(function()
          ctx.done('boom')
        end, 10)
      end),
      step('after', trace),
    },
  })
  restore()

  t.eq(ok, false, 'the run result')
  t.eq(trace, { 'edit', 'broken' }, 'the steps run')
  t.eq(notices, { { level = levels.WARN, title = 'Fixing Failed', msg = 'boom' } }, 'the notices')
  t.eq(file_lines(buf), { 'fixed' }, 'the file on disk')
  vim.cmd.bwipeout()
end)

t.test('a step that throws fails like one that reports an error', function()
  local notices, restore = record_notices()
  local trace = {}
  local buf = modified_file('throw.txt')

  local ok = run({
    buf = buf,
    steps = {
      step('thrower', trace, function()
        error('kaboom')
      end),
      step('after', trace),
    },
  })
  restore()

  t.eq(ok, false, 'the run result')
  t.eq(trace, { 'thrower' }, 'the steps run')
  t.eq(
    notices,
    { { level = levels.WARN, title = 'Fixing Failed', msg = 'thrower' } },
    'the notices'
  )
  t.eq(run({ buf = buf, steps = {} }), true, 'a new run after the failure')
  vim.cmd.bwipeout()
end)

t.test('the timeout ends the run: no later step, notice or edit, lock released', function()
  local notices, restore_notices = record_notices()
  local events, _, restore_progress = record_progress()
  local trace = {}
  local late_done = false
  local buf = modified_file('timeout.txt')

  local ok = run({
    buf = buf,
    timeout_ms = 50,
    steps = {
      step('slow', trace, function(ctx)
        vim.defer_fn(function()
          late_done = true
          ctx.done()
        end, 150)
      end),
      step('edit', trace, function(ctx)
        vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, { 'late edit' })
        ctx.done('late failure')
      end),
    },
  })

  t.eq(ok, false, 'the run result')
  t.eq(events, { { 'start', 'Running slow' }, { 'finish' } }, 'the progress')
  t.eq(run({ buf = buf, save = false, steps = {} }), true, 'a new run while the slow step runs on')

  t.wait_for(function()
    return late_done
  end, 'the slow step reporting late')
  t.settle(50)
  restore_notices()
  restore_progress()

  t.eq(trace, { 'slow' }, 'the steps run')
  t.eq(
    notices,
    { { level = levels.WARN, title = 'Style Enforcer', msg = 'Running slow timed out' } },
    'the notices'
  )
  t.eq(buf_lines(buf), { 'edited' }, 'the buffer')
  t.eq(file_lines(buf), { 'saved' }, 'the file on disk')
  vim.cmd.bwipeout({ bang = true })
end)

t.test('a run on a buffer already running warns and runs nothing', function()
  local trace = {}
  local buf = modified_file('locked.txt')
  local first_ok
  style_enforcers.run({
    buf = buf,
    steps = {
      step('slow', trace, function(ctx)
        vim.defer_fn(ctx.done, 50)
      end),
    },
    on_done = function(ok)
      first_ok = ok
    end,
  })

  local notices, restore = record_notices()
  local second_called = false
  style_enforcers.run({
    buf = buf,
    steps = { step('second', trace) },
    on_done = function()
      second_called = true
    end,
  })
  restore()

  t.wait_for(function()
    return first_ok ~= nil
  end, 'the first run')
  t.eq(trace, { 'slow' }, 'the steps run')
  t.eq(
    notices,
    { { level = levels.WARN, title = 'Style Enforcer', msg = 'Formatting already in progress' } },
    'the notices'
  )
  t.eq(second_called, false, 'the second run ended')
  t.eq(first_ok, true, 'the first run result')
  vim.cmd.bwipeout()
end)

t.test('save = false leaves the file alone, the default writes it', function()
  local buf = modified_file('save.txt')
  local function edit(ctx)
    vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, { 'formatted' })
    ctx.done()
  end

  t.eq(run({ buf = buf, save = false, steps = { step('edit', {}, edit) } }), true)
  t.ok(vim.bo[buf].modified, 'written with save = false')
  t.eq(file_lines(buf), { 'saved' }, 'the file after save = false')

  t.eq(run({ buf = buf, steps = { step('edit', {}, edit) } }), true)
  t.eq(vim.bo[buf].modified, false, 'modified after the default save')
  t.eq(file_lines(buf), { 'formatted' }, 'the file after the default save')
  vim.cmd.bwipeout()
end)

-- run_all

t.test('run_all runs every modified buffer, then sums them up once', function()
  local first = modified_file('sum-1.txt')
  local second = modified_file('sum-2.txt')
  -- Synchronous steps: a counter not preset would reach zero after the first buffer
  local steps = {
    step('check', {}, function(ctx)
      ctx.done(ctx.buf == second and 'rejected' or nil)
    end),
  }
  local run_steps = style_enforcers.run
  local _, restore_run = t.spy(style_enforcers, 'run', function(opts)
    return run_steps(vim.tbl_extend('force', opts, { steps = steps }))
  end)
  local notices, restore_notices = record_notices()

  style_enforcers.run_all()
  restore_run()
  restore_notices()

  t.eq(#notices, 2, 'the notices: the failure, then the summary')
  t.eq(notices[1], { level = levels.WARN, title = 'Fixing Failed', msg = 'check' }, 'the failure')
  t.eq(notices[2].level, levels.WARN, 'the summary level')
  t.ok(
    notices[2].msg:match('^Success:\n  .+ sum%-1%.txt\n\nError:\n  .+ sum%-2%.txt$'),
    'the summary: ' .. notices[2].msg
  )
  t.eq(file_lines(first), { 'edited' }, 'the first file')
  t.eq(file_lines(second), { 'edited' }, 'the second file, written after its failure')
  vim.cmd('bwipeout ' .. first .. ' ' .. second)
end)

t.test('run_all warns when no buffer is modified', function()
  local notices, restore = record_notices()
  style_enforcers.run_all()
  restore()

  t.eq(notices, { { level = levels.WARN, title = 'Style Enforcer', msg = 'No buffers to format' } })
end)

-- The real steps

t.test('conform: its failure lists the formatters and points to :ConformInfo', function()
  local notices, restore = record_notices()
  local buf = t.file('broken.lua', { 'local = 1' })

  t.eq(run({ buf = buf, steps = { conform_step } }), false, 'the run result')
  t.eq(run({ buf = buf, steps = { conform_step }, debug = true }), false, 'the debug run result')
  restore()

  t.eq({ notices[1].level, notices[1].title }, { levels.ERROR, 'Formatting Failed' })
  t.eq(
    notices[1].msg,
    'Formatter(s) used: `stylua` \nSee `:ConformInfo` for more information',
    'the notice'
  )
  t.ok(vim.startswith(notices[2].msg, 'Format error: '), 'the debug notice: ' .. notices[2].msg)
  vim.cmd.bwipeout()
end)

t.test('oxfmt: formats a background buffer with its own options, applying the edits', function()
  local buf = t.file('format.ts', { 'const a=1' })
  vim.bo[buf].shiftwidth = 3
  vim.bo[buf].expandtab = true
  local log, stop = serve(buf, 'oxfmt', {
    ['textDocument/formatting'] = function(_, reply)
      vim.defer_fn(function()
        reply(nil, {
          {
            range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 9 } },
            newText = 'const a = 1;',
          },
        })
      end, 10)
    end,
  })
  vim.cmd.enew()
  vim.bo.shiftwidth = 8

  t.eq(run({ buf = buf, steps = { oxfmt } }), true, 'the run result')

  t.eq(methods(log), { 'textDocument/formatting' }, 'the requests')
  t.eq(log[1].params.textDocument.uri, vim.uri_from_bufnr(buf), 'the document')
  t.eq(
    { log[1].params.options.tabSize, log[1].params.options.insertSpaces },
    { 3, true },
    "the target buffer's options"
  )
  t.eq(file_lines(buf), { 'const a = 1;' }, 'the file on disk')
  stop()
  vim.cmd('bwipeout ' .. buf)
end)

t.test('oxfmt: a null reply, for a formatted file, succeeds without an edit', function()
  local buf = t.file('clean.ts', { 'const a = 1;' })
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local _, stop = serve(buf, 'oxfmt', {})

  t.eq(run({ buf = buf, steps = { oxfmt } }), true, 'the run result')
  t.eq(vim.api.nvim_buf_get_changedtick(buf), tick, 'the changedtick')
  stop()
  vim.cmd.bwipeout()
end)

t.test('oxfmt: a reply after the timeout is dropped, making no edit', function()
  local notices, restore = record_notices()
  local buf = t.file('late.ts', { 'const a=1' })
  local replied = false
  local _, stop = serve(buf, 'oxfmt', {
    ['textDocument/formatting'] = function(_, reply)
      vim.defer_fn(function()
        replied = true
        reply(nil, {
          {
            range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 9 } },
            newText = 'const a = 1;',
          },
        })
      end, 150)
    end,
  })
  local trace = {}

  t.eq(run({ buf = buf, timeout_ms = 50, steps = { oxfmt, step('after', trace) } }), false)
  t.wait_for(function()
    return replied
  end, 'the late reply')
  t.settle(50)
  restore()

  t.eq(buf_lines(buf), { 'const a=1' }, 'the buffer')
  t.eq(trace, {}, 'the steps run after oxfmt')
  t.eq(notices, {
    { level = levels.WARN, title = 'Style Enforcer', msg = 'Formatting (oxfmt) timed out' },
  }, 'the notices')
  stop()
  vim.cmd.bwipeout()
end)

t.test("eslint: applyAllFixes for the buffer's version; a server error fails the run", function()
  local notices, restore = record_notices()
  local buf = t.file('fix.ts', { 'var a = 1' })
  local log, stop = serve(buf, 'eslint', {
    ['workspace/executeCommand'] = function(_, reply)
      reply({ code = -32603, message = 'boom' })
    end,
  })
  local version = vim.lsp.util.buf_versions[buf]

  t.eq(run({ buf = buf, steps = { eslint }, debug = true }), false, 'the run result')
  restore()

  t.eq(methods(log), { 'workspace/executeCommand' }, 'the requests')
  t.eq(log[1].params, {
    command = 'eslint.applyAllFixes',
    arguments = { { uri = vim.uri_from_bufnr(buf), version = version } },
  }, 'the command')
  t.eq(
    notices,
    { { level = levels.WARN, title = 'Fixing Failed', msg = 'Linter eslint error: boom' } },
    'the notices'
  )
  stop()
  vim.cmd.bwipeout()
end)

t.test('oxlint: pulls diagnostics before fixAll, so the fix sees the current text', function()
  local buf = t.file('pull.ts', { 'const a = 1' })
  local log, stop = serve(buf, 'oxlint', {
    ['textDocument/diagnostic'] = function(_, reply)
      vim.defer_fn(function()
        reply(nil, { kind = 'full', items = {} })
      end, 10)
    end,
  })

  t.eq(run({ buf = buf, steps = { oxlint } }), true, 'the run result')

  local document = { uri = vim.uri_from_bufnr(buf) }
  t.eq(methods(log), { 'textDocument/diagnostic', 'workspace/executeCommand' }, 'the requests')
  t.eq(log[1].params, { textDocument = document }, 'the pull')
  t.eq(log[2].params, { command = 'oxc.fixAll', arguments = { document } }, 'the fix')
  stop()
  vim.cmd.bwipeout()
end)

t.test('oxlint: an edit during the pull skips fixAll with its own notice', function()
  local notices, restore = record_notices()
  local buf = t.file('race.ts', { 'const a = 1' })
  local log, stop = serve(buf, 'oxlint', {
    ['textDocument/diagnostic'] = function(_, reply)
      vim.defer_fn(function()
        reply(nil, { kind = 'full', items = {} })
      end, 50)
    end,
  })
  vim.defer_fn(function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'const a = 2' })
  end, 10)

  t.eq(run({ buf = buf, steps = { oxlint } }), false, 'the run result')
  restore()

  t.eq(methods(log), { 'textDocument/diagnostic' }, 'the requests')
  t.eq(notices, {
    {
      level = levels.WARN,
      title = 'Style Enforcer',
      msg = 'Buffer changed while `oxlint` was running, skipped',
    },
  }, 'the notices')
  stop()
  vim.cmd.bwipeout({ bang = true })
end)

t.test('an LSP step whose client detached after the gate fails as missing', function()
  local notices, restore = record_notices()
  local buf = t.file('detach.ts', { 'const a = 1' })
  local log, stop = serve(buf, 'oxlint', {})
  local client = vim.lsp.get_clients({ name = 'oxlint', bufnr = buf })[1]

  local ok = run({
    buf = buf,
    debug = true,
    steps = {
      step('detach', {}, function(ctx)
        vim.lsp.buf_detach_client(ctx.buf, client.id)
        ctx.done()
      end),
      oxlint,
    },
  })
  restore()

  t.eq(ok, false, 'the run result')
  t.eq(methods(log), {}, 'the requests')
  t.eq(notices, {
    {
      level = levels.WARN,
      title = 'Fixing Failed',
      msg = 'Linter oxlint error: oxlint client missing',
    },
  }, 'the notices')
  stop()
  vim.cmd.bwipeout()
end)

t.test('progress reads Formatting for conform and oxfmt, Fixing for eslint and oxlint', function()
  local events, _, restore = record_progress()

  -- conform alone: stylua formats Lua, and no LSP step has its client here
  local lua_buf = t.file('labels.lua', UNFORMATTED)
  t.eq(run({ buf = lua_buf }), true, 'the conform run')

  -- The LSP steps alone, conform having no formatter for text; attached out of run order
  local buf = t.file('labels.txt', { 'text' })
  local stops = {}
  for _, name in ipairs({ 'oxlint', 'eslint', 'oxfmt' }) do
    local _, stop = serve(buf, name, {})
    stops[#stops + 1] = stop
  end
  t.eq(run({ buf = buf }), true, 'the LSP run')
  restore()

  t.eq(events, {
    { 'start', 'Formatting' },
    { 'finish' },
    { 'start', 'Formatting (oxfmt)' },
    { 'report', 'Fixing (eslint)', 100 / 3 },
    { 'report', 'Fixing (oxlint)', 200 / 3 },
    { 'finish' },
  }, 'the progress')
  for _, stop in ipairs(stops) do
    stop()
  end
  vim.cmd('bwipeout ' .. lua_buf .. ' ' .. buf)
end)

t.test('oxfmt: its failure reads as formatting', function()
  local notices, restore = record_notices()
  local buf = t.file('invalid.ts', { 'const a =' })
  local _, stop = serve(buf, 'oxfmt', {
    ['textDocument/formatting'] = function(_, reply)
      reply({ code = -32603, message = 'syntax error' })
    end,
  })

  t.eq(run({ buf = buf, steps = { oxfmt } }), false, 'the run result')
  t.eq(run({ buf = buf, steps = { oxfmt }, debug = true }), false, 'the debug run result')
  restore()

  t.eq(notices, {
    { level = levels.ERROR, title = 'Formatting Failed', msg = 'Formatter used: oxfmt' },
    {
      level = levels.ERROR,
      title = 'Formatting Failed',
      msg = 'Formatter oxfmt error: syntax error',
    },
  }, 'the notices')
  stop()
  vim.cmd.bwipeout()
end)
