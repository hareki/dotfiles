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
  local inner = s:sub(2, -2)
  local out = {}
  local i = 1
  while i <= #inner do
    local c = inner:sub(i, i)
    if c == '\\' then
      local oct = inner:match('^([0-7][0-7][0-7])', i + 1)
      if oct then
        out[#out + 1] = string.char(tonumber(oct, 8))
        i = i + 4
      else
        local nxt = inner:sub(i + 1, i + 1)
        out[#out + 1] = C_ESCAPES[nxt] or nxt
        i = i + 2
      end
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

local function strip_path_prefix(path, prefixed)
  -- git appends a TAB (and diff(1) a TAB plus a timestamp) after the name
  -- whenever it contains a space. A real tab in a path is always C-quoted, so
  -- everything from the first raw tab is metadata.
  path = path:gsub('\t.*$', '')
  if path == '/dev/null' then
    return nil
  end
  path = unquote_c_string(path)
  -- With diff.noPrefix (or empty src/dst prefixes) the headers carry bare
  -- paths, and stripping would eat the first segment of a file genuinely under
  -- a top-level a/, b/, w/ ... directory.
  if not prefixed then
    return path
  end
  -- Standard prefixes: a/ b/ plus i/ w/ c/ o/ 1/ 2/ used by mnemonicPrefix.
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
    old_path = nil,
    new_path = nil,
    old_hex = nil,
    new_hex = nil,
    old_mode = nil,
    new_mode = nil,
    is_new = false,
    is_deleted = false,
    is_binary = false,
    renamed_from = nil,
    renamed_to = nil,
    hunks = {},
  }
  -- Whether this file's paths carry the a/ b/ (or mnemonic) prefixes: the diff
  -- line is the one place the form shows, and the ---/+++ headers of the same
  -- file always use the same setting. Only source prefixes can open the line
  -- (a/ plus mnemonic i/ c/ o/ w/ and 1/); b/ and 2/ are destination-only, so
  -- a bare path starting with b/ stays unprefixed.
  file.prefixed = diff_line:match('^diff %-%-git "?[aciow1]/') ~= nil
  -- Path pair from the diff line for the common unquoted case; overridden by
  -- ---/+++ or rename headers when present.
  local a, b = diff_line:match('^diff %-%-git a/(.-) b/(.+)$')
  if a then
    file.old_path, file.new_path = a, b
  end
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
    -- name containing " b/"). Letting that guess survive a header which
    -- refuted it is what forced consumers to ask whether the file was new or
    -- deleted before they could trust either path.
    file.old_path = strip_path_prefix(line:sub(5), file.prefixed)
  elseif vim.startswith(line, '+++ ') then
    file.new_path = strip_path_prefix(line:sub(5), file.prefixed)
  else
    return false
  end
  return true
end

--- A hunk's rows as the patch has them: each side's fragment (the lines that
--- side shows, in order) and the changes between them -- each minus run paired
--- with the plus run that follows it -- as an ordered list of { old_start,
--- old_end, new_start, new_end } (1-based fragment rows, end exclusive) holding
--- the run's own rows in old_rows/new_rows and its per-row char emphasis in
--- old_emph/new_emph (empty until engine.emphasize fills them in). The layouts
--- draw their rows from these, and fragment mode highlights the fragments in
--- place of the blobs; one walk builds both, so a change's rows are fragment
--- rows by construction.
---
--- The rows come from the patch rather than from the diff engine because they
--- are what lazygit stages: the engine is free to slide a change along lines
--- that read the same (a blank line or a brace on either end of a deleted
--- block), and a row drawn as changed would then not be the line that staging
--- it stages.
function M.hunk_rows(hunk)
  local frag_old, frag_new, changes = {}, {}, {}
  local change = nil
  for _, l in ipairs(hunk.lines) do
    local origin, text = l.origin, l.text
    if origin == ' ' then
      change = nil
      frag_old[#frag_old + 1] = text
      frag_new[#frag_new + 1] = text
    else
      -- A minus line after plus lines opens the next change.
      if not change or (origin == '-' and #change.new_rows > 0) then
        change = {
          old_start = #frag_old + 1,
          new_start = #frag_new + 1,
          old_rows = {},
          new_rows = {},
          old_emph = {},
          new_emph = {},
        }
        changes[#changes + 1] = change
      end
      if origin == '-' then
        frag_old[#frag_old + 1] = text
        change.old_rows[#change.old_rows + 1] = text
      else
        frag_new[#frag_new + 1] = text
        change.new_rows[#change.new_rows + 1] = text
      end
      change.old_end, change.new_end = #frag_old + 1, #frag_new + 1
    end
  end
  return frag_old, frag_new, changes
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
  local remaining_old, remaining_new = 0, 0

  -- At most one of raw and file is open: raw only grows while no section is.
  local function flush()
    blocks[#blocks + 1] = raw or file
    raw, file, hunk = nil, nil, nil
  end

  local i = 1
  while i <= #lines do
    local line = lines[i]
    local consumed = true

    if
      vim.startswith(line, 'diff --git ')
      or vim.startswith(line, 'diff --cc ')
      or vim.startswith(line, 'diff --combined ')
    then
      flush()
      file = new_section(line)
    elseif not file then
      if not raw then
        raw = { kind = 'raw', lines = {} }
      end
      raw.lines[#raw.lines + 1] = line
    elseif file.kind == 'combined' then
      if M.is_submodule_line(line) or M.commit_line(line) then
        consumed = false
      else
        file.lines[#file.lines + 1] = line
      end
    elseif line:match('^@@ %-%d') then
      local os_, oc, ns, nc, heading = line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@ ?(.*)$')
      if os_ then
        hunk = {
          old_start = tonumber(os_),
          old_count = oc ~= '' and tonumber(oc) or 1,
          new_start = tonumber(ns),
          new_count = nc ~= '' and tonumber(nc) or 1,
          heading = heading ~= '' and heading or nil,
          lines = {},
        }
        remaining_old, remaining_new = hunk.old_count, hunk.new_count
        file.hunks[#file.hunks + 1] = hunk
      else
        consumed = false
      end
    elseif not hunk then
      consumed = parse_extended_header(file, line)
    else
      local origin = line:sub(1, 1)
      if line == '\\ No newline at end of file' then
        -- It marks the line before it, a side's last, which is always among
        -- the hunk's last rows: the note renders once, after the hunk.
        if hunk.lines[1] then
          hunk.no_newline = true
        end
      elseif origin == '-' and remaining_old > 0 then
        hunk.lines[#hunk.lines + 1] = { origin = '-', text = line:sub(2) }
        remaining_old = remaining_old - 1
      elseif origin == '+' and remaining_new > 0 then
        hunk.lines[#hunk.lines + 1] = { origin = '+', text = line:sub(2) }
        remaining_new = remaining_new - 1
      elseif (origin == ' ' or line == '') and (remaining_old > 0 or remaining_new > 0) then
        -- "" is an empty context line with the leading space trimmed.
        hunk.lines[#hunk.lines + 1] = { origin = ' ', text = line:sub(2) }
        remaining_old = remaining_old - 1
        remaining_new = remaining_new - 1
      else
        consumed = false
      end
    end

    if consumed then
      i = i + 1
    else
      -- Line does not belong to the open section: close it and reprocess the
      -- same line with no section open.
      flush()
    end
  end

  flush()
  return blocks
end

return M
