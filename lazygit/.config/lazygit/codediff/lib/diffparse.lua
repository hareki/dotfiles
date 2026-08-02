local util = require("lib.util")

local M = {}

local function strip_path_prefix(path)
  -- git appends a TAB (and diff(1) a TAB plus a timestamp) after the name
  -- whenever it contains a space. A real tab in a path is always C-quoted, so
  -- everything from the first raw tab is metadata.
  path = path:gsub("\t.*$", "")
  if path == "/dev/null" then
    return nil
  end
  path = util.unquote_c_string(path)
  -- Standard prefixes: a/ b/ plus i/ w/ c/ o/ 1/ 2/ used by mnemonicPrefix.
  local stripped = path:match("^[abciwo12]/(.+)$")
  return stripped or path
end

local function new_file(diff_line)
  local file = {
    kind = "file",
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
  if diff_line:match("^diff %-%-git ") then
    -- Path pair from the diff line for the common unquoted case; overridden
    -- by ---/+++ or rename headers when present.
    local a, b = diff_line:match("^diff %-%-git a/(.-) b/(.+)$")
    if a then
      file.old_path, file.new_path = a, b
    end
  else
    file.is_combined = true
    local p = diff_line:match("^diff %-%-c%S* (.+)$")
    file.new_path = p and util.unquote_c_string(p) or nil
  end
  return file
end

-- Returns true when the line was consumed as an extended header.
local function parse_extended_header(file, line)
  if line:match("^old mode %d") then
    file.old_mode = line:match("^old mode (%d+)")
  elseif line:match("^new mode %d") then
    file.new_mode = line:match("^new mode (%d+)")
  elseif line:match("^new file mode %d") then
    file.is_new = true
    file.new_mode = line:match("^new file mode (%d+)")
  elseif line:match("^deleted file mode %d") then
    file.is_deleted = true
    file.old_mode = line:match("^deleted file mode (%d+)")
  elseif line:match("^similarity index %d+%%$") or line:match("^dissimilarity index %d+%%$") then
    -- consumed, nothing to record
  elseif line:match("^rename from ") then
    file.renamed_from = util.unquote_c_string(line:sub(#"rename from " + 1))
    file.old_path = file.renamed_from
  elseif line:match("^rename to ") then
    file.renamed_to = util.unquote_c_string(line:sub(#"rename to " + 1))
    file.new_path = file.renamed_to
  elseif line:match("^copy from ") then
    file.renamed_from = util.unquote_c_string(line:sub(#"copy from " + 1))
  elseif line:match("^copy to ") then
    file.renamed_to = util.unquote_c_string(line:sub(#"copy to " + 1))
    file.new_path = file.renamed_to
  elseif line:match("^index %x+%.%.%x+") then
    file.old_hex, file.new_hex = line:match("^index (%x+)%.%.(%x+)")
  elseif line:match("^Binary files ") or line:match("^GIT binary patch") then
    file.is_binary = true
  elseif line:match("^%-%-%- ") then
    local p = strip_path_prefix(line:sub(5))
    if p then
      file.old_path = p
    end
  elseif line:match("^%+%+%+ ") then
    local p = strip_path_prefix(line:sub(5))
    if p then
      file.new_path = p
    end
  else
    return false
  end
  return true
end

--- Parse raw `git diff` / `git show` output into an ordered list of blocks:
--- { kind = "raw", lines }  preamble, commit header/message, --stat, submodules
--- { kind = "file", ... }   one per "diff --git/--cc/--combined" section
function M.parse(lines)
  local blocks = {}
  local raw = nil
  local file = nil
  local hunk = nil
  local remaining_old, remaining_new = 0, 0
  -- states: "top" | "header" | "hunk" | "combined"
  local state = "top"

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
    state = "top"
  end

  local i = 1
  while i <= #lines do
    local line = util.strip_cr(lines[i])
    local consumed = true

    if line:match("^diff %-%-git ") or line:match("^diff %-%-cc ") or line:match("^diff %-%-combined ") then
      flush_file()
      flush_raw()
      file = new_file(line)
      state = file.is_combined and "combined" or "header"
    elseif state == "top" then
      if not raw then
        raw = { kind = "raw", lines = {} }
      end
      raw.lines[#raw.lines + 1] = line
    elseif state == "combined" then
      if line:match("^Submodule ") or line:match("^commit %x") then
        consumed = false
      else
        file.raw_lines[#file.raw_lines + 1] = line
      end
    elseif line:match("^@@ %-%d") and (state == "header" or state == "hunk") then
      local os_, oc, ns, nc, heading = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@ ?(.*)$")
      if os_ then
        hunk = {
          old_start = tonumber(os_),
          old_count = oc ~= "" and tonumber(oc) or 1,
          new_start = tonumber(ns),
          new_count = nc ~= "" and tonumber(nc) or 1,
          heading = heading ~= "" and heading or nil,
          lines = {},
        }
        remaining_old, remaining_new = hunk.old_count, hunk.new_count
        file.hunks[#file.hunks + 1] = hunk
        state = "hunk"
      else
        consumed = false
      end
    elseif state == "header" then
      if not parse_extended_header(file, line) then
        consumed = false
      end
    elseif state == "hunk" then
      local origin = line:sub(1, 1)
      if line == "\\ No newline at end of file" then
        local prev = hunk.lines[#hunk.lines]
        if prev then
          prev.no_newline = true
        end
      elseif origin == "-" and remaining_old > 0 then
        hunk.lines[#hunk.lines + 1] = { origin = "-", text = line:sub(2) }
        remaining_old = remaining_old - 1
      elseif origin == "+" and remaining_new > 0 then
        hunk.lines[#hunk.lines + 1] = { origin = "+", text = line:sub(2) }
        remaining_new = remaining_new - 1
      elseif (origin == " " or line == "") and (remaining_old > 0 or remaining_new > 0) then
        -- "" is an empty context line with the leading space trimmed.
        hunk.lines[#hunk.lines + 1] = { origin = " ", text = line:sub(2) }
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
