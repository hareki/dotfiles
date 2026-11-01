local M = {}

-- The named escapes of git's C-style quoting; any other escaped character (\"
-- and \\) stands for itself.
local C_ESCAPES = { a = '\a', b = '\b', t = '\t', n = '\n', v = '\v', f = '\f', r = '\r' }

-- Unquote a git C-style quoted path ("a\"b", "\303\251" octal escapes, etc).
-- Returns the input unchanged when it is not quoted.
local function unquote_c_string(s)
  if s:sub(1, 1) ~= '"' or s:sub(-1) ~= '"' then
    return s
  end
  -- An octal escape is exactly three digits. Anything else stands for itself,
  -- and the digits the pattern took along behind it are plain text.
  return (
    s:sub(2, -2):gsub('\\(.?)([0-7]?[0-7]?)', function(c, rest)
      if #rest == 2 and c:find('[0-7]') then
        return string.char(tonumber(c .. rest, 8))
      end
      return (C_ESCAPES[c] or c) .. rest
    end)
  )
end

local function strip_path_prefix(path)
  -- git appends a TAB (and diff(1) a TAB plus a timestamp) after the name
  -- whenever it contains a space. A real tab in a path is always C-quoted, so
  -- everything from the first raw tab is metadata.
  path = path:gsub('\t.*$', '')
  if path == '/dev/null' then
    return nil
  end
  path = unquote_c_string(path)
  -- Standard prefixes: a/ b/ plus i/ w/ c/ o/ 1/ 2/ used by mnemonicPrefix.
  -- lazygit asks for one on every diff it shows, whatever diff.noPrefix says
  -- (ParseableDiffPrefixes), so a bare path never gets here.
  local stripped = path:match('^[abciwo12]/(.+)$')
  return stripped or path
end

-- The block a "diff --git/--cc/--combined" line opens. A combined (merge) diff
-- is kept verbatim, for passthrough to tint by prefix: nothing else about it
-- is a file this renderer lays out.
local function new_section(diff_line)
  if not vim.startswith(diff_line, 'diff --git ') then
    local p = diff_line:match('^diff %-%-c%S* (.+)$')
    return { kind = 'combined', path = p and unquote_c_string(p) or nil, lines = {} }
  end
  local file = {
    kind = 'file',
    is_new = false,
    is_deleted = false,
    is_binary = false,
    hunks = {},
    -- What the hunks hold, which is what lib/blob.lua's section caps and
    -- lib/core.lua's highlighting budget go by.
    hunk_lines = 0,
    hunk_bytes = 0,
  }
  -- Path pair from the diff line for the common unquoted case; overridden by
  -- ---/+++ or rename headers when present.
  file.old_path, file.new_path = diff_line:match('^diff %-%-git a/(.-) b/(.+)$')
  return file
end

-- "<header> <mode>" lines: the mode to capture, the field it fills, and the
-- flag it raises. Capturing answers both "is this the line" and "what is in
-- it", so neither prefix has to be spelled twice.
local MODE_HEADERS = {
  { '^old mode (%d+)', 'old_mode' },
  { '^new mode (%d+)', 'new_mode' },
  { '^new file mode (%d+)', 'new_mode', 'is_new' },
  { '^deleted file mode (%d+)', 'old_mode', 'is_deleted' },
}

-- "<header> <path>" lines: the path to capture, the field it fills, and the
-- path field it also becomes. `copy from` deliberately has no second field: a
-- copy leaves the source file alone, so it is not this diff's old side.
local PATH_HEADERS = {
  { '^rename from (.*)$', 'renamed_from', 'old_path' },
  { '^rename to (.*)$', 'renamed_to', 'new_path' },
  { '^copy from (.*)$', 'renamed_from' },
  { '^copy to (.*)$', 'renamed_to', 'new_path' },
}

-- Returns true when the line was consumed as an extended header.
local function parse_extended_header(file, line)
  for _, header in ipairs(MODE_HEADERS) do
    local mode = line:match(header[1])
    if mode then
      file[header[2]] = mode
      if header[3] then
        file[header[3]] = true
      end
      return true
    end
  end
  for _, header in ipairs(PATH_HEADERS) do
    local path = line:match(header[1])
    if path then
      path = unquote_c_string(path)
      file[header[2]] = path
      if header[3] then
        file[header[3]] = path
      end
      return true
    end
  end

  local old_hex, new_hex = line:match('^index (%x+)%.%.(%x+)')
  if old_hex then
    file.old_hex, file.new_hex = old_hex, new_hex
  elseif line:match('^similarity index %d+%%$') or line:match('^dissimilarity index %d+%%$') then
    -- consumed, nothing to record
  elseif vim.startswith(line, 'Binary files ') or vim.startswith(line, 'GIT binary patch') then
    file.is_binary = true
  elseif vim.startswith(line, '--- ') then
    -- Authoritative for this side, including the nil that /dev/null resolves
    -- to: the header is the diff's own answer for the side, where the path
    -- pair new_section() reads off the diff line is only a guess (it mis-splits a
    -- name containing " b/").
    file.old_path = strip_path_prefix(line:sub(5))
  elseif vim.startswith(line, '+++ ') then
    file.new_path = strip_path_prefix(line:sub(5))
  else
    return false
  end
  return true
end

-- One side of a hunk, from the two numbers of its @@ header; a count git left out
-- is 1.
local function new_side(start, count)
  return {
    start = tonumber(start),
    count = count ~= '' and tonumber(count) or 1,
    rows = {},
    emph = {},
  }
end

--- Add a line of the patch to `hunk`, and return the change left open after it.
--- A hunk has an `old` and a `new` side, { start, count, rows, emph }: `rows` are
--- the lines the side shows, in order, and whatever else is known about a row
--- (engine's char emphasis, core's spans, osc1717's records) is keyed by the same
--- 1-based row. hunk.changes pairs each minus run with the plus run that follows
--- it, as an ordered list of { old_start, old_end, new_start, new_end } (rows, end
--- exclusive). One walk builds both, so a change's rows are side rows by
--- construction.
---
--- The rows come from the patch rather than from the diff engine because they
--- are what lazygit stages: the engine is free to slide a change along lines
--- that read the same (a blank line or a brace on either end of a deleted
--- block), and a row drawn as changed would then not be the line that staging
--- it stages.
local function add_row(file, hunk, change, origin, text)
  local old, new = hunk.old.rows, hunk.new.rows
  file.hunk_lines = file.hunk_lines + 1
  file.hunk_bytes = file.hunk_bytes + #text
  if origin == ' ' then
    old[#old + 1], new[#new + 1] = text, text
    return nil
  end
  -- A minus line after plus lines opens the next change.
  if not change or (origin == '-' and change.new_end > change.new_start) then
    change = { old_start = #old + 1, new_start = #new + 1 }
    hunk.changes[#hunk.changes + 1] = change
  end
  local rows = origin == '-' and old or new
  rows[#rows + 1] = text
  change.old_end, change.new_end = #old + 1, #new + 1
  return change
end

--- Walk a hunk's rows in order, handing each run to the callback for it. Between
--- changes the two sides' pointers advance in step, which is both the pairing
--- the side-by-side layout draws and the numbering everything else prints -- so
--- the bookkeeping lives here rather than once per caller.
function M.walk_hunk(hunk, on_context, on_change)
  local old_ptr, new_ptr = 1, 1
  local function context_rows(count)
    for _ = 1, count do
      on_context(old_ptr, new_ptr)
      old_ptr, new_ptr = old_ptr + 1, new_ptr + 1
    end
  end
  for _, change in ipairs(hunk.changes) do
    context_rows(change.new_start - new_ptr)
    on_change(change)
    old_ptr, new_ptr = change.old_end, change.new_end
  end
  context_rows(#hunk.new.rows - new_ptr + 1)
end

--- The hash and decorations of the "commit <hash> (refs)" line that opens a
--- `git show`, nil for any other line. Exported because the combined-diff body
--- below ends at one, core.render reads it to tell git output from arbitrary
--- text, and passthrough styles it: git's line grammar is this module's to
--- know, not something each consumer keeps its own copy of the pattern for.
function M.commit_line(line)
  return line:match('^commit (%x+)%s*(.*)$')
end

--- True for the "Submodule <path> <range>" line git writes for a submodule's
--- change (--submodule=log), which also ends a combined-diff body.
function M.is_submodule_line(line)
  return vim.startswith(line, 'Submodule ')
end

--- Parse raw `git diff` / `git show` output into an ordered list of blocks:
--- { kind = "raw", lines }        preamble, commit header/message, --stat, submodules
--- { kind = "file", ... }         one per "diff --git" section
--- { kind = "combined", path, lines }  one per "diff --cc/--combined" section
function M.parse(lines)
  local blocks = {}
  local raw = nil
  --- @type table?
  local file = nil
  --- @type table?
  local hunk = nil
  local change = nil

  -- At most one of raw and file is open: raw only grows while no section is.
  local function flush()
    blocks[#blocks + 1] = raw or file
    raw, file, hunk = nil, nil, nil
  end

  -- A line that does not belong to the open section closes it.
  local function raw_line(line)
    if file then
      flush()
    end
    raw = raw or { kind = 'raw', lines = {} }
    raw.lines[#raw.lines + 1] = line
  end

  for _, line in ipairs(lines) do
    if
      vim.startswith(line, 'diff --git ')
      or vim.startswith(line, 'diff --cc ')
      or vim.startswith(line, 'diff --combined ')
    then
      flush()
      file = new_section(line)
    elseif not file then
      raw_line(line)
    elseif file.kind == 'combined' then
      if M.is_submodule_line(line) or M.commit_line(line) then
        raw_line(line)
      else
        file.lines[#file.lines + 1] = line
      end
    elseif line:match('^@@ %-%d') then
      local os_, oc, ns, nc, heading = line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@ ?(.*)$')
      if os_ then
        hunk = {
          old = new_side(os_, oc),
          new = new_side(ns, nc),
          heading = heading ~= '' and heading or nil,
          changes = {},
        }
        change = nil
        file.hunks[#file.hunks + 1] = hunk
      else
        raw_line(line)
      end
    elseif not hunk then
      if not parse_extended_header(file, line) then
        raw_line(line)
      end
    else
      local origin = line:sub(1, 1)
      local old_left = #hunk.old.rows < hunk.old.count
      local new_left = #hunk.new.rows < hunk.new.count
      if line == '\\ No newline at end of file' then
        -- It marks the line before it, a side's last, which is always among
        -- the hunk's last rows: the note renders once, after the hunk.
        hunk.no_newline = true
      elseif origin == '-' and old_left then
        change = add_row(file, hunk, change, '-', line:sub(2))
      elseif origin == '+' and new_left then
        change = add_row(file, hunk, change, '+', line:sub(2))
      elseif (origin == ' ' or line == '') and (old_left or new_left) then
        -- "" is an empty context line with the leading space trimmed.
        change = add_row(file, hunk, change, ' ', line:sub(2))
      else
        raw_line(line)
      end
    end
  end

  flush()
  return blocks
end

return M
