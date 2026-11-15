-- How a render degrades when the content, the size or the clock is against it.
--
--   nvim --clean -l tests/degrade.lua
--
-- A file is highlighted from its whole content when that is at hand and agrees with the patch,
-- from its hunks when it is not, and past the caps not at all. Each step down is reached here
-- through core.render alone, on a diff git makes in a throwaway repository, and read off the
-- rendered rows: syntax shows as more than one foreground color in a row's text, changed words
-- as a second background.

local dir = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ':p'))
package.path = dir .. '/../?.lua;' .. package.path

local t = require('tests.lib.t')

require('lib.bootstrap').setup()
local core = require('lib.core')

local function commit(repo)
  t.git(repo, { 'add', '-A' })
  t.git(repo, { 'commit', '-q', '-m', 'change' })
end

--- The diff of the last commit, the way lazygit asks for one.
local function last_diff(repo, ...)
  return t.git(repo, { 'diff', '--no-ext-diff', '--unified=3', 'HEAD~1', 'HEAD', '--', ... })
end

--- The colors of the first inline row showing `needle` (see t.row_colors), and whether the
--- render may be cached.
local function render(input, cwd, needle)
  local rendered, cacheable = core.render(input, { cwd = cwd, cols = 100 })
  return t.row_colors(rendered, needle), cacheable
end

--- A repository whose last commit changes one line of code that sits inside a block comment
--- opened `padding` lines above it. Parsed with the file, the line is a comment; parsed with
--- its hunk alone, it is code.
local function change_inside_comment(padding)
  local repo = t.repo()
  local filler = string.rep(string.rep('filler ', 11) .. '\n', padding)
  local function content(answer)
    return '--[[\n' .. filler .. 'local answer = ' .. answer .. '\n' .. filler .. ']]\nreturn {}\n'
  end
  t.write(repo .. '/note.lua', content(1))
  commit(repo)
  t.write(repo .. '/note.lua', content(2))
  commit(repo)
  return repo, last_diff(repo)
end

--- A repository whose last commit changes every one of `lines` lines of z-values.lua, and adds
--- a-new.lua with `new_lines` lines when given.
local function change_every_line(lines, new_lines)
  local repo = t.repo()
  local function content(offset)
    local out = {}
    for i = 1, lines do
      out[i] = ('local value_%d = %d\n'):format(i, i + offset)
    end
    return table.concat(out)
  end
  t.write(repo .. '/z-values.lua', content(0))
  commit(repo)
  t.write(repo .. '/z-values.lua', content(1))
  if new_lines then
    t.write(repo .. '/a-new.lua', string.rep('local added = true\n', new_lines))
  end
  commit(repo)
  return repo
end

t.freeze_clock()

t.test('a worktree file edited since the diff is highlighted from its hunks', function()
  local fixture = t.fixture('full-unstaged')
  -- A script with no extension: only its first line, which no hunk shows, says it is bash.
  t.ok(render(fixture.input, fixture.cwd, 'rsync -az').fg > 1, 'no syntax with the file at hand')

  local path = fixture.cwd .. '/bin/deploy'
  t.write(path, (t.read(path):gsub('rsync %-az', 'rsync -a')))
  t.eq(render(fixture.input, fixture.cwd, 'rsync -az').fg, 1, 'foreground colors')
end)

t.test('a blob past the highlight cap is highlighted from its hunks', function()
  local repo, diff = change_inside_comment(10)
  t.eq(render(diff, repo, 'local answer = 2').fg, 1, 'a small file, parsed whole')

  -- 78 bytes a line, on both sides of the change: well past 256KB
  repo, diff = change_inside_comment(2000)
  t.ok(render(diff, repo, 'local answer = 2').fg > 1, 'a large file was parsed whole')
end)

t.test('a section past the caps keeps its tints and loses syntax and changed words', function()
  local repo = change_every_line(10)
  local colors = render(last_diff(repo), repo, 'local value_5 = 6')
  t.ok(colors.fg > 1, 'no syntax in a small section')
  t.eq(colors.bg, 2, 'backgrounds in a small section')

  -- Every line both removed and added: past 20000 hunk lines
  repo = change_every_line(10100)
  t.eq(render(last_diff(repo), repo, 'local value_5 = 6'), { fg = 1, bg = 1 })
end)

t.test('a file past the highlight budget loses syntax and keeps its changed words', function()
  -- The new file comes first in the diff and takes the whole budget of 8000 lines.
  local repo = change_every_line(3, 8001)
  local alone = render(last_diff(repo, 'z-values.lua'), repo, 'local value_2 = 3')
  t.ok(alone.fg > 1, 'no syntax in a diff of its own')
  t.eq(render(last_diff(repo), repo, 'local value_2 = 3'), { fg = 1, bg = 2 })
end)

t.test('a finished render may be cached', function()
  local repo = change_every_line(3)
  local colors, cacheable = render(last_diff(repo), repo, 'local value_2 = 3')
  t.ok(colors.fg > 1, 'no syntax')
  t.eq(cacheable, true, 'cacheable')
end)

t.test('an input past the size cap goes back as it came, uncached', function()
  local input = 'diff --git a/x b/x\n' .. string.rep('+line\n', 400000)
  local rendered, cacheable = core.render(input, { cwd = '/', cols = 100 })
  t.ok(rendered == input, 'the input was rendered')
  t.eq(cacheable, false, 'cacheable')
end)

t.test('text that is not from git goes back as it came, uncached', function()
  local input = t.fixture('colored-log').input
  local rendered, cacheable = core.render(input, { cwd = '/', cols = 100 })
  t.ok(rendered == input, 'the input was rendered')
  t.eq(cacheable, false, 'cacheable')
end)

t.test('a render past the highlight deadline is tint-only and must not be cached', function()
  local repo = change_every_line(3)
  local diff = last_diff(repo)
  -- The first reading sets the deadline, and every later one is past it.
  local readings = 0
  t.with_clock(function()
    readings = readings + 1
    return readings == 1 and 0 or 1e12
  end, function()
    local colors, cacheable = render(diff, repo, 'local value_2 = 3')
    t.eq(colors.fg, 1, 'foreground colors')
    t.eq(cacheable, false, 'cacheable')
  end)
end)

t.done()
