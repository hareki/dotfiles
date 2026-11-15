--- What a test file uses: tests reporting a line each, fixtures and goldens, a throwaway repo, a
--- clock to stop and a row's colors. Each runs in its own `nvim --clean -l` and ends in t.done().
local M = {}

local tests_dir = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))

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

--- A test file's last line; os.exit would leave nvim's temp dir, and every t.tmpdir(), behind.
function M.done()
  vim.cmd.cquit({ count = failed and 1 or 0 })
end

function M.read(path)
  return vim.fn.readblob(path)
end

function M.write(path, content)
  local file = assert(io.open(path, 'wb'))
  file:write(content)
  file:close()
end

--- A new directory inside nvim's own temp directory, which goes when the test file ends.
function M.tmpdir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, 'p')
  return path
end

--- Run git in `cwd` for its stdout, the user's config left out so a fixture hashes alike anywhere.
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

--- A throwaway repository. With `source`, a fixture's .repo dir: objects/ become blobs, worktree/
--- the worktree, each object checked against its oid so an edited fixture file fails by name.
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

--- The layouts a fixture renders in, and the suffix of the golden each one has.
M.layouts = { 'inline', 'side-by-side' }
local GOLDEN_SUFFIX = { inline = '.out', ['side-by-side'] = '.split.out' }

--- Where the golden of the fixture `name` in `layout` is kept.
function M.golden_path(name, layout)
  return vim.fs.joinpath(M.fixtures, name .. GOLDEN_SUFFIX[layout])
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

--- A fixture's diff and where it renders: a repository built from fixtures/<name>.repo when there
--- is one, else /, with no blobs to find and no worktree to fall back on.
function M.fixture(name)
  local source = vim.fs.joinpath(M.fixtures, name .. '.repo')
  return {
    input = M.read(vim.fs.joinpath(M.fixtures, name .. '.diff')),
    cwd = vim.uv.fs_stat(source) and M.repo(source) or '/',
  }
end

--- Stop the highlight deadline's clock (vim.uv.hrtime) for the file, so no render goes tint-only.
function M.freeze_clock()
  vim.uv.hrtime = function()
    return 0
  end
end

--- Run `body` with `clock` standing in for that clock.
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
  return #vim.iter(text:gmatch(selector .. ';2;(%d+;%d+;%d+)')):unique():totable()
end

--- The foreground and background color counts past the gutter of the first inline row holding
--- `needle`: one foreground means no syntax, two backgrounds changed words picked out in a row.
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
