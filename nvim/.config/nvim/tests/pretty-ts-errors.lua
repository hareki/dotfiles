-- features.diagnostics.eagle-nvim.pretty-ts-errors: format() through a faked CLI (vim.system), its
-- cache and the one-spawn-per-line batching. The module's cache and its latch outlive a test, so
-- each test formats messages of its own, and the latch test comes last

local t = require('tests.lib.helpers')
local pretty_ts_errors = require('features.diagnostics.eagle-nvim.pretty-ts-errors')

local CLI = 'pretty-ts-errors-markdown'
local CACHE_CAP = 512

--- @class tests.pretty-ts-errors.Cli
--- @field events string[] `spawn <message>` and `wait <message>`, in order
--- @field inputs table[] The JSON each spawn got on stdin, decoded

--- Fake the CLI until the test ends: each spawn reads its diagnostic from stdin, and its wait
--- returns reply(input), by default markdown led by a header line
--- @param reply? fun(input: table): vim.SystemCompleted
--- @return tests.pretty-ts-errors.Cli
local function fake_cli(reply)
  reply = reply
    or function(input)
      return { code = 0, signal = 0, stdout = '[header](link)\n\n**' .. input.message .. '**\n' }
    end
  local cli = { events = {}, inputs = {} }
  t.set(vim, 'system', function(cmd, opts)
    t.eq(cmd, { CLI }, 'the command')
    local input = vim.json.decode(opts.stdin)
    cli.inputs[#cli.inputs + 1] = input
    cli.events[#cli.events + 1] = 'spawn ' .. input.message
    return {
      wait = function()
        cli.events[#cli.events + 1] = 'wait ' .. input.message
        return reply(input)
      end,
    }
  end)
  return cli
end

--- @param cli tests.pretty-ts-errors.Cli
--- @return integer
local function spawns(cli)
  return #vim.tbl_filter(function(event)
    return vim.startswith(event, 'spawn ')
  end, cli.events)
end

local LSP_RANGE = { start = { line = 0, character = 6 }, ['end'] = { line = 0, character = 7 } }

--- A TypeScript diagnostic on line `lnum` of a buffer that has no other, as eagle hands it over
--- @param message string
--- @param lnum? integer
--- @return vim.Diagnostic
local function diagnostic(message, lnum)
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    lnum = lnum or 0,
    col = 6,
    message = message,
    source = 'ts',
    code = 2322,
    severity = vim.diagnostic.severity.ERROR,
    user_data = { lsp = { range = LSP_RANGE } },
  }
end

t.test('a miss runs the CLI on stdin and drops its header; a hit runs nothing', function()
  local cli = fake_cli()
  t.buffer('typescript', { 'const a: string = 1' })

  t.eq(pretty_ts_errors.format(diagnostic('first')), '**first**', 'the markdown')
  t.eq(cli.inputs, {
    {
      range = LSP_RANGE,
      message = 'first',
      code = 2322,
      severity = vim.diagnostic.severity.ERROR,
      source = 'ts',
      relatedInformation = {},
    },
  }, 'the input')

  -- Edits above the error move it: the cache ignores where it is
  local moved = diagnostic('first', 4)
  moved.user_data.lsp.range = { start = { line = 4, character = 0 }, ['end'] = LSP_RANGE['end'] }
  t.eq(pretty_ts_errors.format(moved), '**first**', 'the markdown of the moved error')
  t.eq(spawns(cli), 1, 'the spawns')
end)

t.test("a miss formats the line's other uncached diagnostics of its source at once", function()
  local cli = fake_cli()
  local buf = t.buffer('typescript', { 'const a: string = 1', 'const b: number = ""' })
  local ns = vim.api.nvim_create_namespace('tests.pretty-ts-errors')
  t.cleanup(function()
    vim.diagnostic.reset(ns, buf)
  end)
  local stored = {}
  for _, entry in ipairs({
    { 'batch one', 'ts', 0 },
    { 'batch two', 'ts', 0 },
    { 'batch lint', 'eslint', 0 },
    { 'batch next line', 'ts', 1 },
  }) do
    local d = diagnostic(entry[1], entry[3])
    d.source = entry[2]
    stored[#stored + 1] = d
  end
  vim.diagnostic.set(ns, buf, stored)
  local one = vim.diagnostic.get(buf, { lnum = 0 })[1]

  t.eq(pretty_ts_errors.format(one), '**batch one**', 'the markdown')
  -- Both spawned before either is waited for: the popup waits for the slowest, not their sum
  t.eq({ cli.events[1], cli.events[2] }, { 'spawn batch one', 'spawn batch two' }, 'the spawns')
  local waits = { cli.events[3], cli.events[4] }
  table.sort(waits)
  t.eq(waits, { 'wait batch one', 'wait batch two' }, 'the waits after them')
  t.eq(#cli.events, 4, 'the CLI events')

  t.eq(pretty_ts_errors.format(diagnostic('batch two')), '**batch two**', 'the batched one')
  t.eq(spawns(cli), 2, 'the spawns after formatting the batched one')
end)

t.test('a CLI failure, or no output, falls back to the raw message, kept', function()
  local cli = fake_cli(function(input)
    if input.message == 'failing' then
      return { code = 1, signal = 0, stdout = '', stderr = 'boom' }
    end
    return { code = 0, signal = 0, stdout = '' }
  end)
  t.buffer('typescript', { 'const a: string = 1' })

  t.eq(pretty_ts_errors.format(diagnostic('failing')), 'failing', 'a failed run')
  t.eq(pretty_ts_errors.format(diagnostic('silent')), 'silent', 'a run without output')
  t.eq(pretty_ts_errors.format(diagnostic('failing')), 'failing', 'the failed one again')
  t.eq(spawns(cli), 2, 'the spawns')
end)

t.test('the cache holds 512 entries, wiped by the next', function()
  local cli = fake_cli()
  t.buffer('typescript', { 'const a: string = 1' })
  local function cached(message)
    local before = spawns(cli)
    pretty_ts_errors.format(diagnostic(message))
    return spawns(cli) == before
  end

  -- Fill the cache to its first wipe, which `probe` then misses: two entries left, known ones
  pretty_ts_errors.format(diagnostic('probe'))
  local filler = 0
  repeat
    filler = filler + 1
    pretty_ts_errors.format(diagnostic('filler ' .. filler))
    t.ok(filler <= CACHE_CAP, 'no wipe in a cache of 512 entries')
  until not cached('probe')

  for i = 3, CACHE_CAP do
    pretty_ts_errors.format(diagnostic('full ' .. i))
  end
  t.ok(cached('probe'), 'the oldest entry of a full cache')
  t.ok(cached('full ' .. CACHE_CAP), 'the newest entry of a full cache')

  pretty_ts_errors.format(diagnostic('overflow'))
  t.eq(cached('full ' .. CACHE_CAP), false, 'an entry from before the wipe')
  t.ok(cached('overflow'), 'the entry that wiped it')
end)

t.test('a failed spawn turns the CLI off: later misses are raw, spawning nothing', function()
  local calls = t.spy(vim, 'system', function()
    error('ENOENT: no such file or directory')
  end)
  t.buffer('typescript', { 'const a: string = 1' })

  t.eq(pretty_ts_errors.format(diagnostic('unavailable')), 'unavailable', 'the failed spawn')
  t.eq(pretty_ts_errors.format(diagnostic('after it')), 'after it', 'a later miss')
  t.eq(#calls, 1, 'the spawns')
end)
