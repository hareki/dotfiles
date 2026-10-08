-- OSC 1717 record checks for the codediff renderer.
--
--   nvim --clean -l tests/records.lua
--
-- Every fixture is rendered with records in both layouts, and its records have
-- to name exactly the lines of git's patch, numbered the way lazygit numbers
-- them (LineNumberOfLine and OldLineNumberOfLine in its pkg/commands/patch):
-- that is what lazygit stages by. A render without records must carry none.

local script = arg and arg[0] or debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(script, ':p:h')
package.path = dir .. '/../?.lua;' .. package.path

require('lib.bootstrap').setup()
local core = require('lib.core')
local diffparse = require('lib.diffparse')
local util = require('lib.util')

local RECORD = '\27%]1717;([^\7]*)\7'

-- The records git's patch calls for, in patch order: a hunk header numbered by
-- the first line of the new side, a deletion by the new-file line it sits at
-- and its own old-file line, anything else by its new-file line.
local function expected_records(input)
  local records = {}
  for _, block in ipairs(diffparse.parse(util.split_lines(input))) do
    if block.kind == 'file' and not block.is_combined and not block.is_binary then
      local path = block.new_path or block.old_path
      for _, hunk in ipairs(block.hunks) do
        records[#records + 1] = ('h;%d;;%s'):format(hunk.new_start, path)
        local old, new = hunk.old_start, hunk.new_start
        for _, line in ipairs(hunk.lines) do
          if line.origin == ' ' then
            records[#records + 1] = ('c;%d;;%s'):format(new, path)
            old, new = old + 1, new + 1
          elseif line.origin == '-' then
            records[#records + 1] = ('d;%d;%d;%s'):format(new, old, path)
            old = old + 1
          else
            records[#records + 1] = ('a;%d;;%s'):format(new, path)
            new = new + 1
          end
        end
      end
    end
  end
  return records
end

-- The records a rendering carries, row by row as lazygit collects them: the
-- distinct ones of each row, left to right. File-header records are left out,
-- since nothing in the patch's lines calls for them.
local function rendered_records(rendered)
  local records = {}
  for _, row in ipairs(vim.split(rendered, '\n', { plain = true })) do
    local seen = {}
    for payload in row:gmatch(RECORD) do
      local record = payload:match('^1;(.*)$')
      if record and not seen[record] and not record:match('^f;') then
        seen[record] = true
        records[#records + 1] = record
      end
    end
  end
  return records
end

local fail = false
local function report(ok, name, what, detail)
  io.write(('%s %s (%s)%s\n'):format(ok and 'ok     ' or 'FAILED ', name, what, detail or ''))
  fail = fail or not ok
end

local fixtures = {}
for name, kind in vim.fs.dir(dir .. '/fixtures') do
  if kind == 'file' and name:sub(-5) == '.diff' then
    fixtures[#fixtures + 1] = name
  end
end
table.sort(fixtures)

for _, name in ipairs(fixtures) do
  local f = assert(io.open(dir .. '/fixtures/' .. name, 'rb'))
  local input = f:read('*a')
  f:close()
  local expected = expected_records(input)

  for _, layout in ipairs({ 'inline', 'side-by-side' }) do
    local function render(metadata)
      return (
        core.render(
          input,
          { cwd = dir, cols = 100, layout = layout, force_fragment = true, metadata = metadata }
        )
      )
    end

    local actual = rendered_records(render(true))
    -- A side-by-side row pairs a deletion with an addition, so only the inline
    -- layout keeps the patch's order.
    if layout == 'side-by-side' then
      table.sort(actual)
      expected = vim.deepcopy(expected)
      table.sort(expected)
    end
    if vim.deep_equal(actual, expected) then
      report(true, name, layout .. ' records')
    else
      report(
        false,
        name,
        layout .. ' records',
        ('\n  expected %s\n  actual   %s'):format(
          table.concat(expected, ' '),
          table.concat(actual, ' ')
        )
      )
    end

    if render(false):find('\27]1717', 1, true) then
      report(false, name, layout .. ' without records', ': records found')
    end
  end
end

os.exit(fail and 1 or 0)
