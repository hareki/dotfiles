-- Golden-output checks for the codediff renderer.
--
--   nvim --clean -l tests/goldens.lua            compare every fixture against its goldens
--   nvim --clean -l tests/goldens.lua --update   rewrite the goldens
--
-- A fixture is fixtures/<name>.diff, rendered in both layouts at a fixed width and compared
-- with <name>.out and <name>.split.out. The OSC 1717 records lazygit asks for are checked
-- separately, against the fixtures' own patches (see records.lua).
--
-- A render reads more than the diff: the blobs the diff names, and the worktree files behind
-- the ones git has no blob for. So a fixture renders in one of two places:
--
--   at /                       no repository, so every file is highlighted from its hunks
--   in a throwaway repository  built from fixtures/<name>.repo, when the fixture has one
--
-- To give a fixture its repository, run these in the repository the diff was taken from:
--
--   git cat-file blob <oid> > <name>.repo/objects/<oid>   for each oid on an "index" line
--   rsync -R <path> <name>.repo/worktree/                 for a side git has no blob for
--
-- An oid git has no blob for is the new side of an unstaged change, and the worktree file is
-- that side.

local dir = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ':p'))
package.path = dir .. '/../?.lua;' .. package.path

local t = require('tests.lib.t')
local update = arg[1] == '--update'

require('lib.bootstrap').setup()
local core = require('lib.core')

--- Where two renders part: the line number and that line on each side, escapes spelled out.
local function first_difference(actual, expected)
  local a = vim.split(actual, '\n', { plain = true })
  local e = vim.split(expected, '\n', { plain = true })
  for i = 1, math.max(#a, #e) do
    if a[i] ~= e[i] then
      return ('line %d\n  golden   %s\n  rendered %s'):format(
        i,
        vim.inspect(e[i]),
        vim.inspect(a[i])
      )
    end
  end
end

t.freeze_clock()

for _, name in ipairs(t.fixture_names()) do
  local fixture = t.fixture(name)
  for _, layout in ipairs(t.layouts) do
    local golden_path = t.golden_path(name, layout)
    t.test(('%s (%s)'):format(name, layout), function()
      local rendered =
        core.render(fixture.input, { cwd = fixture.cwd, cols = 100, layout = layout })
      if update then
        t.write(golden_path, rendered)
        return
      end
      t.ok(vim.uv.fs_stat(golden_path), 'no golden: run tests/run.sh --update')
      local golden = t.read(golden_path)
      if rendered ~= golden then
        error(first_difference(rendered, golden), 0)
      end
    end)
  end
end

t.done()
