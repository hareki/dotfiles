-- What the daemon does with a request (lib/request.lua), without the daemon.
--
--   nvim --clean -l tests/request.lua
--
-- One request goes through the real renderer, line to output file; every other test meets a
-- stand-in renderer that counts its calls and answers what the test needs.

local dir = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ':p'))
package.path = dir .. '/../?.lua;' .. package.path

local t = require('tests.lib.t')

require('lib.bootstrap').setup()
local core = require('lib.core')

local work = t.tmpdir()
local made = 0

--- The two files of a request, as a client makes them: the input written, the output empty.
local function files(input)
  made = made + 1
  local infile, outfile = ('%s/in.%d'):format(work, made), ('%s/out.%d'):format(work, made)
  t.write(infile, input)
  t.write(outfile, '')
  return infile, outfile
end

--- A request line for `infile` and `outfile`, with `fields` over the defaults.
local function line(infile, outfile, fields)
  fields = fields or {}
  return table.concat({
    infile,
    outfile,
    fields.cols or '100',
    fields.layout or 'inline',
    fields.metadata or '0',
    fields.cwd or '/',
  }, '\t')
end

local real_render = core.render

--- A request module that has cached nothing, `render` standing in for the renderer when given.
local function fresh_request(render)
  core.render = render or real_render
  package.loaded['lib.request'] = nil
  return require('lib.request')
end

--- A stand-in renderer, with its `calls` and the last call's options; it answers `result`, or what
--- `result` returns for the input when that is a function.
local function stand_in(result, cacheable)
  local seen = { calls = 0 }
  local function render(input, opts)
    seen.calls = seen.calls + 1
    seen.opts = opts
    return type(result) == 'function' and result(input) or result, cacheable
  end
  return render, seen
end

--- Send `input` as a request and return the answer and what reached the output file.
local function send(request, input, fields)
  local infile, outfile = files(input)
  local answer = request.handle(line(infile, outfile, fields))
  return answer, t.read(outfile)
end

t.freeze_clock()

t.test('a request renders its input file into its output file', function()
  local answer, output = send(fresh_request(), t.fixture('lua-small').input)
  t.eq(answer, true, 'answer')
  t.ok(output == t.read(t.golden_path('lua-small', 'inline')), 'the output is not the golden')
end)

t.test('the line reaches the renderer as typed options, the directory to its last tab', function()
  local render, seen = stand_in('rendered', true)
  send(
    fresh_request(render),
    'input',
    { cols = '87', layout = 'side-by-side', metadata = '1', cwd = '/a dir/with\ta tab' }
  )
  t.eq(
    seen.opts,
    { cols = 87, layout = 'side-by-side', metadata = true, cwd = '/a dir/with\ta tab' }
  )
end)

t.test('a line that is not a request is refused', function()
  local render, seen = stand_in('rendered', true)
  local request = fresh_request(render)
  local infile, outfile = files('input')
  t.eq(request.handle(''), false, 'an empty line')
  t.eq(request.handle(infile .. '\t' .. outfile .. '\t100\tinline\t0'), false, 'five fields')
  t.eq(request.handle(line(infile, outfile, { metadata = 'yes' })), false, 'metadata "yes"')
  t.eq(seen.calls, 0, 'renders')
end)

t.test('an output file is only ever opened, never made', function()
  local request = fresh_request(stand_in('rendered', true))
  local infile, outfile = files('input')
  os.remove(outfile)
  t.eq(request.handle(line(infile, outfile)), false, 'answer')
  t.eq(vim.uv.fs_stat(outfile), nil, 'the output file')
end)

t.test('a missing input file is refused', function()
  local request = fresh_request(stand_in('rendered', true))
  local infile, outfile = files('input')
  os.remove(infile)
  t.eq(request.handle(line(infile, outfile)), false, 'answer')
end)

t.test('the same request renders once', function()
  local render, seen = stand_in(string.upper, true)
  local request = fresh_request(render)
  t.eq({ send(request, 'input') }, { true, 'INPUT' }, 'first')
  t.eq({ send(request, 'input') }, { true, 'INPUT' }, 'second')
  t.eq(seen.calls, 1, 'renders')
end)

t.test('another input, width, layout, metadata or directory renders again', function()
  local render, seen = stand_in(string.upper, true)
  local request = fresh_request(render)
  send(request, 'input')
  for _, other in ipairs({
    { 'other input' },
    { 'input', { cols = '99' } },
    { 'input', { layout = 'side-by-side' } },
    { 'input', { metadata = '1' } },
    { 'input', { cwd = '/tmp' } },
  }) do
    local before = seen.calls
    send(request, other[1], other[2])
    t.eq(seen.calls, before + 1, 'renders after ' .. vim.inspect(other, { newline = '' }))
  end
end)

t.test('a render that may not be cached renders again', function()
  local render, seen = stand_in('rendered', false)
  local request = fresh_request(render)
  send(request, 'input')
  t.eq({ send(request, 'input') }, { true, 'rendered' }, 'second')
  t.eq(seen.calls, 2, 'renders')
end)

t.test('a render that raises answers with the input as it came, and is not cached', function()
  local calls = 0
  local request = fresh_request(function()
    calls = calls + 1
    error('the renderer broke')
  end)
  t.eq({ send(request, 'the diff') }, { true, 'the diff' }, 'first')
  send(request, 'the diff')
  t.eq(calls, 2, 'renders')
end)

t.test('past 24 renders the one used longest ago goes, and a hit counts as a use', function()
  local render, seen = stand_in(string.upper, true)
  local request = fresh_request(render)
  send(request, 'first')
  send(request, 'second')
  send(request, 'first')
  for i = 1, 23 do
    send(request, 'filler ' .. i)
  end
  t.eq(seen.calls, 25, 'renders so far')

  send(request, 'first')
  t.eq(seen.calls, 25, 'renders after asking for the one that was used again')
  send(request, 'second')
  t.eq(seen.calls, 26, 'renders after asking for the one that was not')
end)

t.test('past 32MB of renders the oldest goes, and one that large is never kept', function()
  local size = 12 * 1024 * 1024
  local render, seen = stand_in(function(input)
    return string.rep(input:sub(1, 1), input == 'huge' and 3 * size or size)
  end, true)
  local request = fresh_request(render)
  for _, input in ipairs({ 'a', 'b', 'c' }) do
    send(request, input)
  end
  send(request, 'c')
  t.eq(seen.calls, 3, 'renders after asking for the newest again')
  send(request, 'a')
  t.eq(seen.calls, 4, 'renders after asking for the oldest again')

  send(request, 'huge')
  send(request, 'huge')
  t.eq(seen.calls, 6, 'renders after asking twice for one larger than the cache')
  send(request, 'a')
  t.eq(seen.calls, 6, 'renders after asking for one the large render must not push out')
end)

t.done()
