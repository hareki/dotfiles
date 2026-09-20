local util = require('lib.util')

local M = {}

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
      local nxt = inner:sub(i + 1, i + 1)
      local oct = inner:match('^([0-7][0-7][0-7])', i + 1)
      if oct then
        out[#out + 1] = string.char(tonumber(oct, 8))
        i = i + 4
      elseif nxt == 'n' then
        out[#out + 1] = '\n'
        i = i + 2
      elseif nxt == 't' then
        out[#out + 1] = '\t'
        i = i + 2
      elseif nxt == 'r' then
        out[#out + 1] = '\r'
        i = i + 2
      else
        out[#out + 1] = nxt
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

local function new_file(diff_line)
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
    is_combined = false,
    renamed_from = nil,
    renamed_to = nil,
    hunks = {},
    raw_lines = {}, -- combined-diff body kept verbatim
  }
  if vim.startswith(diff_line, 'diff --git ') then
    -- Whether this file's paths carry the a/ b/ (or mnemonic) prefixes: the
    -- diff line is the one place the form shows, and the ---/+++ headers of
    -- the same file always use the same setting. Only source prefixes can
    -- open the line (a/ plus mnemonic i/ c/ o/ w/ and 1/); b/ and 2/ are
    -- destination-only, so a bare path starting with b/ stays unprefixed.
    file.prefixed = diff_line:match('^diff %-%-git "?[aciow1]/') ~= nil
    -- Path pair from the diff line for the common unquoted case; overridden
    -- by ---/+++ or rename headers when present.
    local a, b = diff_line:match('^diff %-%-git a/(.-) b/(.+)$')
    if a then
      file.old_path, file.new_path = a, b
    end
  else
    file.is_combined = true
    local p = diff_line:match('^diff %-%-c%S* (.+)$')
    file.new_path = p and unquote_c_string(p) or nil
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

  if line:match('^similarity index %d+%%$') or line:match('^dissimilarity index %d+%%$') then
    -- consumed, nothing to record
  elseif line:match('^index %x+%.%.%x+') then
    file.old_hex, file.new_hex = line:match('^index (%x+)%.%.(%x+)')
  elseif vim.startswith(line, 'Binary files ') or vim.startswith(line, 'GIT binary patch') then
    file.is_binary = true
  elseif vim.startswith(line, '--- ') then
    -- Authoritative for this side, including the nil that /dev/null resolves
    -- to: the header is the diff's own answer for the side, where the path
    -- pair new_file() reads off the diff line is only a guess (it mis-splits a
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

--- Reconstruct one side of a hunk from the patch itself: the lines that side
--- shows, in order. Both the diff engine and the fallback renderer consume
--- these per-hunk fragments.
function M.hunk_fragment(hunk, side)
  local lines = {}
  local want_minus = side == 'old'
  for _, l in ipairs(hunk.lines) do
    if
      l.origin == ' '
      or (want_minus and l.origin == '-')
      or (not want_minus and l.origin == '+')
    then
      lines[#lines + 1] = l.text
    end
  end
  return lines
end

--- Parse raw `git diff` / `git show` output into an ordered list of blocks:
--- { kind = "raw", lines }  preamble, commit header/message, --stat, submodules
--- { kind = "file", ... }   one per "diff --git/--cc/--combined" section
function M.parse(lines)
  local blocks = {}
  local raw = nil
  -- `state` already implies which of these two are set ("top": neither,
  -- "hunk": both), but LuaLS cannot see that, so the branches below test them
  -- alongside the state.
  --- @type table?
  local file = nil
  --- @type table?
  local hunk = nil
  local remaining_old, remaining_new = 0, 0
  -- states: "top" | "header" | "hunk" | "combined"
  local state = 'top'

  local function flush_raw()
    if raw then
      blocks[#blocks + 1] = raw
      raw = nil
    end
  end

  local function flush_file()
    if file then
      blocks[#blocks + 1] = file
      file = nil
    end
    hunk = nil
    state = 'top'
  end

  local i = 1
  while i <= #lines do
    local line = util.strip_cr(lines[i])
    local consumed = true

    if
      vim.startswith(line, 'diff --git ')
      or vim.startswith(line, 'diff --cc ')
      or vim.startswith(line, 'diff --combined ')
    then
      flush_file()
      flush_raw()
      file = new_file(line)
      state = file.is_combined and 'combined' or 'header'
    elseif state == 'top' then
      if not raw then
        raw = { kind = 'raw', lines = {} }
      end
      raw.lines[#raw.lines + 1] = line
    elseif file and state == 'combined' then
      if vim.startswith(line, 'Submodule ') or line:match('^commit %x') then
        consumed = false
      else
        file.raw_lines[#file.raw_lines + 1] = line
      end
    elseif file and line:match('^@@ %-%d') and (state == 'header' or state == 'hunk') then
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
        state = 'hunk'
      else
        consumed = false
      end
    elseif state == 'header' then
      if not parse_extended_header(file, line) then
        consumed = false
      end
    elseif hunk and state == 'hunk' then
      local origin = line:sub(1, 1)
      if line == '\\ No newline at end of file' then
        local prev = hunk.lines[#hunk.lines]
        if prev then
          prev.no_newline = true
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
    else
      consumed = false
    end

    if consumed then
      i = i + 1
    else
      -- Line does not belong to the open section: close it and reprocess the
      -- same line from the top state.
      flush_file()
    end
  end

  flush_file()
  flush_raw()
  return blocks
end

return M
