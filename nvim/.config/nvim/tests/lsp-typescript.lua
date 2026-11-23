-- Which server owns a TypeScript project, asked through the root_dir of tsc and vtsls: tsc where
-- TypeScript 7+ is installed, vtsls otherwise, neither where 7+ is declared but not installed

local t = require('tests.lib.helpers')

--- @param version string
--- @return string manifest
local function package_json(version)
  return vim.json.encode({ version = version })
end

--- Write a project under the boot's cwd: a lockfile at its top marks the project root. The owner
--- is sticky per directory with no reset, so every test takes a directory of its own
--- @param name string
--- @param files table<string, string> Contents by path, relative to the project
--- @return string root
local function project(name, files)
  local root = vim.fs.joinpath(vim.uv.cwd(), name)
  files = vim.tbl_extend('keep', files, { ['package-lock.json'] = '{}' })
  for path, content in pairs(files) do
    t.write(vim.fs.joinpath(name, path), vim.split(content, '\n'))
  end
  return root
end

--- The directory each server's root_dir answers for a buffer on `file`, nil where it stays silent
--- @param file string
--- @return { tsc: string?, vtsls: string? }
local function roots(file)
  -- Not a scratch buffer: vim.fs.root() searches from the cwd for a buffer with a 'buftype'
  local buf = vim.api.nvim_create_buf(false, false)
  t.cleanup(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
  vim.api.nvim_buf_set_name(buf, file)

  local answers = {}
  for _, server in ipairs({ 'tsc', 'vtsls' }) do
    vim.lsp.config[server].root_dir(buf, function(root)
      answers[server] = root
    end)
  end
  -- Gone before the next ask on the same file, which would name a second buffer the same
  vim.api.nvim_buf_delete(buf, { force = true })
  return answers
end

--- Record the one-time warnings sent until the test ends, showing none
--- @return table[] calls
local function spy_warnings()
  return t.spy(vim, 'notify_once', function() end)
end

t.test('TypeScript 7 installed gives tsc the directory holding it', function()
  local root = project('ts7', {
    ['package.json'] = '{ "devDependencies": { "typescript": "^7.0.0" } }',
    ['node_modules/typescript/package.json'] = package_json('7.0.0'),
  })

  t.eq(roots(vim.fs.joinpath(root, 'src/index.ts')), { tsc = root })
end)

t.test('TypeScript 5 installed gives vtsls the project root', function()
  local root = project('ts5', {
    ['package.json'] = '{ "devDependencies": { "typescript": "^5.6.0" } }',
    ['node_modules/typescript/package.json'] = package_json('5.6.3'),
  })

  t.eq(roots(vim.fs.joinpath(root, 'src/index.ts')), { vtsls = root })
end)

t.test('no TypeScript at all gives vtsls, which brings its own', function()
  local root = project('no-ts', { ['package.json'] = '{ "name": "plain" }' })

  t.eq(roots(vim.fs.joinpath(root, 'index.js')), { vtsls = root })
end)

t.test('TypeScript 7 declared but not installed gives neither, with a warning', function()
  local warnings = spy_warnings()
  local root = project('ts7-declared', {
    ['package.json'] = '{ "dependencies": { "typescript": "~7.1.0" } }',
  })

  t.eq(roots(vim.fs.joinpath(root, 'index.ts')), {})
  t.ok(#warnings > 0, 'no warning')
  t.ok(warnings[1][1]:find(root, 1, true), 'the warning names the project: ' .. warnings[1][1])
end)

t.test('an npm alias to TypeScript 7 counts as 7', function()
  spy_warnings()
  local root = project('ts7-alias', {
    ['package.json'] = vim.json.encode({
      devDependencies = { typescript = 'npm:@typescript/native-preview@^7.0.0-dev' },
    }),
  })

  t.eq(roots(vim.fs.joinpath(root, 'index.ts')), {})
end)

t.test('the native package wins over a typescript package beside it', function()
  local root = project('native', {
    ['node_modules/@typescript/native/package.json'] = package_json('7.0.0'),
    ['node_modules/typescript/package.json'] = package_json('6.0.2'),
  })

  t.eq(roots(vim.fs.joinpath(root, 'index.ts')), { tsc = root })
end)

t.test('the nearest install decides over a nearer declaration', function()
  local root = project('monorepo', {
    ['node_modules/typescript/package.json'] = package_json('7.0.0'),
    ['packages/app/package.json'] = '{ "devDependencies": { "typescript": "^5.6.0" } }',
  })

  t.eq(roots(vim.fs.joinpath(root, 'packages/app/src/index.ts')), { tsc = root })
end)

t.test('an install above the project root does not count', function()
  local outer = project('outer', {
    ['node_modules/typescript/package.json'] = package_json('7.0.0'),
    ['app/package-lock.json'] = '{}',
  })
  local root = vim.fs.joinpath(outer, 'app')

  t.eq(roots(vim.fs.joinpath(root, 'index.ts')), { vtsls = root })
end)

t.test('a Deno project gives neither, without a warning', function()
  local warnings = spy_warnings()
  local root = project('deno', { ['deno.json'] = '{}' })

  t.eq(roots(vim.fs.joinpath(root, 'main.ts')), {})
  t.eq(#warnings, 0, 'warnings')
end)

t.test("a directory keeps its first owner when the project's TypeScript changes", function()
  local root = project('sticky', {
    ['node_modules/typescript/package.json'] = package_json('5.6.3'),
  })
  local file = vim.fs.joinpath(root, 'index.ts')
  t.eq(roots(file), { vtsls = root }, 'the first answer')

  project('sticky', { ['node_modules/typescript/package.json'] = package_json('7.0.0') })
  t.eq(roots(file), { vtsls = root }, 'after installing TypeScript 7')
end)

t.test('a directory owned by neither is asked again, so an install starts tsc', function()
  spy_warnings()
  local root = project('install-later', {
    ['package.json'] = '{ "devDependencies": { "typescript": "^7.0.0" } }',
  })
  local file = vim.fs.joinpath(root, 'index.ts')
  t.eq(roots(file), {}, 'before the install')

  project('install-later', { ['node_modules/typescript/package.json'] = package_json('7.0.0') })
  t.eq(roots(file), { tsc = root }, 'after the install')
end)
