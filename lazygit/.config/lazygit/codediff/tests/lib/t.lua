--- What a test file uses: tests that report a line each, the fixtures, a throwaway repository to
--- render in, a clock to pin, and a reading of a rendered row's colors. Each file runs in its own
--- `nvim --clean -l` (tests/run.sh), sets package.path to the renderer's directory, and ends with
--- t.done().
local M = {}

local tests_dir = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))

--- The renderer's directory, and its fixtures.
M.root = vim.fs.dirname(tests_dir)
M.fixtures = vim.fs.joinpath(tests_dir, 'fixtures')

local failed = false

--- Run `fn` as a test: one "ok" line, or "FAILED" with what it raised.
function M.test(name, fn)
  local ok, err = pcall(fn)
  io.write(('%-7s %s\n'):format(ok and 'ok' or 'FAILED', name))
  if not ok then
    failed = true
    io.write('  ' .. tostring(err):gsub('\n', '\n  ') .. '\n')
  end
end

function M.eq(actual, expected, what)
  if not vim.deep_equal(actual, expected) then
    error(
      ('%sexpected %s, got %s'):format(
        what and (what .. ': ') or '',
        vim.inspect(expected),
        vim.inspect(actual)
      ),
      0
    )
  end
end

function M.ok(value, what)
  if not value then
    error(what or 'expected a truthy value', 0)
  end
  return value
end

--- Last line of a test file. Not os.exit, which leaves nvim's temp directory behind, and with it
--- every directory t.tmpdir() made.
function M.done()
  vim.cmd.cquit({ count = failed and 1 or 0 })
end

function M.read(path)
  return vim.fn.readblob(path)
end

--- A new directory inside nvim's own temp directory, which goes when the test file ends.
function M.tmpdir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, 'p')
  return path
end

--- Run git in `cwd` and return its stdout. The user's git config stays out of it, so a fixture
--- hashes and diffs the same on every machine.
function M.git(cwd, args, stdin)
  local result = vim
    .system(vim.list_extend({ 'git' }, args), {
      cwd = cwd,
      stdin = stdin,
      env = {
        GIT_CONFIG_GLOBAL = '/dev/null',
        GIT_CONFIG_SYSTEM = '/dev/null',
        GIT_AUTHOR_NAME = 'Test',
        GIT_AUTHOR_EMAIL = 'test@example.com',
        GIT_COMMITTER_NAME = 'Test',
        GIT_COMMITTER_EMAIL = 'test@example.com',
      },
    })
    :wait()
  if result.code ~= 0 then
    error(('git %s: %s'):format(table.concat(args, ' '), result.stderr), 0)
  end
  return result.stdout
end

--- A throwaway repository. With `source`, a fixture's .repo directory: every file in its
--- objects/ becomes a blob in the object database, and its worktree/ becomes the worktree. An
--- object is named by the oid the fixture's diff has for it, which is checked here, so a fixture
--- file that was edited fails by name instead of quietly rendering from its hunks.
function M.repo(source)
  local repo = M.tmpdir()
  M.git(repo, { 'init', '-q' })
  if not source then
    return repo
  end
  local objects = vim.fs.joinpath(source, 'objects')
  for name in vim.fs.dir(objects) do
    local content = M.read(vim.fs.joinpath(objects, name))
    local oid = vim.trim(M.git(repo, { 'hash-object', '-w', '--stdin' }, content))
    M.ok(vim.startswith(oid, name), ('%s/%s hashes to %s'):format(objects, name, oid))
  end
  local worktree = vim.fs.joinpath(source, 'worktree')
  if vim.uv.fs_stat(worktree) then
    vim.system({ 'cp', '-R', worktree .. '/.', repo }):wait()
  end
  return repo
end

--- The fixture names, sorted: every fixtures/<name>.diff.
function M.fixture_names()
  local names = {}
  for _, path in ipairs(vim.fn.glob(M.fixtures .. '/*.diff', true, true)) do
    names[#names + 1] = vim.fs.basename(path):gsub('%.diff$', '')
  end
  table.sort(names)
  return names
end

--- A fixture's diff and the directory it renders in: a throwaway repository built from
--- fixtures/<name>.repo when there is one, and otherwise /, where there are no blobs to find and
--- no worktree to fall back on.
function M.fixture(name)
  local source = vim.fs.joinpath(M.fixtures, name .. '.repo')
  return {
    name = name,
    input = M.read(vim.fs.joinpath(M.fixtures, name .. '.diff')),
    cwd = vim.uv.fs_stat(source) and M.repo(source) or '/',
  }
end

--- Run `body` with `clock` standing in for vim.uv.hrtime, the clock the highlight deadline goes
--- by. A constant one keeps a busy machine from showing up as a tint-only render.
function M.with_clock(clock, body)
  local real = vim.uv.hrtime
  vim.uv.hrtime = clock
  local ok, err = pcall(body)
  vim.uv.hrtime = real
  if not ok then
    error(err, 0)
  end
end

local function count_distinct(text, selector)
  local seen, n = {}, 0
  for color in text:gmatch(selector .. ';2;(%d+;%d+;%d+)') do
    if not seen[color] then
      seen[color] = true
      n = n + 1
    end
  end
  return n
end

--- How many foreground and background colors the text of an inline row carries, past its
--- gutter: the first row of `rendered` whose text holds `needle`. One foreground is a row
--- without syntax colors, and two backgrounds are a changed row with its changed words picked
--- out.
function M.row_colors(rendered, needle)
  for row in rendered:gmatch('[^\n]+') do
    local text = row:match('│(.*)$')
    if text and text:gsub('\27%[[%d;]*m', ''):find(needle, 1, true) then
      return { fg = count_distinct(text, '38'), bg = count_distinct(text, '48') }
    end
  end
  error(('no rendered row holds %q'):format(needle), 0)
end

return M
