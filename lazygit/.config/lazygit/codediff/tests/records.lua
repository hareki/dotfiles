-- OSC 1717 record checks for the codediff renderer.
--
--   nvim --clean -l tests/records.lua
--
-- Each fixture's records, in both layouts, must name exactly the patch's lines as lazygit numbers
-- them (LineNumberOfLine, OldLineNumberOfLine) to stage by; a render without records has none.
--
-- The expectation is read off the fixture's text, never the renderer's parser, whose mistakes it
-- would share.

local dir = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ':p'))
package.path = dir .. '/../?.lua;' .. package.path

local t = require('tests.lib.t')

require('lib.bootstrap').setup()
local core = require('lib.core')

local RECORD = '\27%]1717;([^\7]*)\7'

local ESCAPES = { t = '\t', n = '\n' }

-- The bytes a terminal acts on rather than shows: everything below a space but the tab, and DEL.
local CONTROL = '[%z\1-\8\10-\31\127]'

--- The path a "--- a/<path>" or "+++ b/<path>" line names, nil for /dev/null; git tabs off a name
--- with a space and quotes one needing escapes (octal bytes, the backslash escapes fixtures use).
local function header_path(line)
  local path = line:sub(5):gsub('\t.*$', '')
  if path == '/dev/null' then
    return nil
  end
  if path:sub(1, 1) == '"' then
    path = path
      :sub(2, -2)
      :gsub('\\(%d%d%d)', function(octal)
        return string.char(tonumber(octal, 8))
      end)
      :gsub('\\(.)', function(c)
        return ESCAPES[c] or c
      end)
  end
  return (path:gsub('^[ab]/', ''))
end

--- The records git's patch calls for, in patch order, numbered as lazygit numbers them; a deleted
--- file is named by its old path, one with a control byte in its name or a combined diff gets none.
local function expected_records(input)
  local records = {}
  local old_path, path
  --- @type number, number, number, number
  local old, new, old_left, new_left = 0, 0, 0, 0

  local function record(...)
    if not path:find(CONTROL) then
      records[#records + 1] = string.format(...)
    end
  end

  for line in input:gmatch('([^\n]*)\n') do
    if old_left > 0 or new_left > 0 then
      local origin = line:sub(1, 1)
      if origin == '-' then
        record('d;%d;%d;%s', new, old, path)
        old, old_left = old + 1, old_left - 1
      elseif origin == '+' then
        record('a;%d;;%s', new, path)
        new, new_left = new + 1, new_left - 1
      elseif origin ~= '\\' then
        -- A context line, or an empty one whose leading space was trimmed. The backslash line
        -- is git's note on the line before it, not a line of the file.
        record('c;%d;;%s', new, path)
        old, old_left = old + 1, old_left - 1
        new, new_left = new + 1, new_left - 1
      end
    elseif line:find('^diff ') then
      old_path, path = nil, nil
    elseif line:find('^%-%-%- ') then
      old_path = header_path(line)
    elseif line:find('^%+%+%+ ') then
      path = header_path(line) or old_path
    else
      local old_start, old_count, new_start, new_count =
        line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@')
      if old_start then
        old, new = assert(tonumber(old_start)), assert(tonumber(new_start))
        -- A count git left out is 1.
        old_left, new_left = tonumber(old_count) or 1, tonumber(new_count) or 1
        record('h;%d;;%s', new, path)
      end
    end
  end
  return records
end

--- The patch's files with no hunk (an empty file made or removed, a mode change, a binary file),
--- which only a file-header record names; read off a plain, same-path "diff --git" line.
local function files_without_hunks(input)
  local files, file = {}, nil
  for line in input:gmatch('([^\n]*)\n') do
    if line:find('^diff ') then
      file = line:match('^diff %-%-git a/(.+) b/%1$')
      if file then
        files[file] = true
      end
    elseif file and line:find('^@@ ') then
      files[file] = nil
    end
  end
  return vim.tbl_keys(files)
end

--- The records a rendering carries, row by row and left to right, with the file-header records'
--- files kept apart; a record lasts to its row's end, so one stated twice in a row is a failure.
local function rendered_records(rendered)
  local records, headed = {}, {}
  for _, row in ipairs(vim.split(rendered, '\n', { plain = true })) do
    local seen = {}
    for payload in row:gmatch(RECORD) do
      local record = payload:match('^1;(.*)$')
      if record and record:match('^f;') then
        headed[t.ok(record:match('^f;;;(.+)$'), 'not a file-header record: ' .. record)] = true
      elseif record then
        t.ok(not seen[record], 'a row states a record twice: ' .. record)
        seen[record] = true
        records[#records + 1] = record
      end
    end
  end
  return records, headed
end

t.freeze_clock()

for _, name in ipairs(t.fixture_names()) do
  local fixture = t.fixture(name)
  local expected = expected_records(fixture.input)
  local hunkless = files_without_hunks(fixture.input)

  for _, layout in ipairs(t.layouts) do
    t.test(('%s (%s records)'):format(name, layout), function()
      local function render(metadata)
        return core.render(
          fixture.input,
          { cwd = fixture.cwd, cols = 100, layout = layout, metadata = metadata }
        )
      end

      local actual, headed = rendered_records(render(true))
      for _, path in ipairs(hunkless) do
        t.ok(headed[path], 'no record names ' .. path)
      end
      -- A side-by-side row pairs a deletion with an addition: only inline keeps the patch's order.
      local want = expected
      if layout == 'side-by-side' then
        table.sort(actual)
        want = vim.deepcopy(expected)
        table.sort(want)
      end
      if not vim.deep_equal(actual, want) then
        error(
          ('expected %s\n  actual   %s'):format(table.concat(want, ' '), table.concat(actual, ' ')),
          0
        )
      end

      t.ok(
        not render(false):find('\27]1717', 1, true),
        'a render that was not asked for records carries some'
      )
    end)
  end
end

t.done()
