local M = {}

-- codediff.nvim is required lazily and behind pcall: a missing or broken
-- plugin must degrade to the patch's own line runs, never break the render.
local diff_mod, compat_mod

local function get_diff()
  if diff_mod == nil then
    local ok, mod = pcall(require, "codediff.core.diff")
    diff_mod = ok and mod or false
  end
  return diff_mod or nil
end

local function get_compat()
  if compat_mod == nil then
    local ok, mod = pcall(require, "codediff.core.compat")
    compat_mod = ok and mod or false
  end
  return compat_mod or nil
end

-- Mirrors codediff's utf16_col_to_byte_col (ui/inline.lua): engine columns are
-- 1-based UTF-16 code units, end-exclusive.
local function utf16_col_to_byte_col(line, utf16_col)
  if not line or utf16_col <= 1 then
    return utf16_col
  end
  local compat = get_compat()
  if compat then
    local ok, byte_idx = pcall(compat.str_byteindex_utf16, line, utf16_col - 1)
    if ok then
      return byte_idx + 1
    end
  end
  return utf16_col
end

-- Split one side of the char-level inner changes into per-row byte ranges:
-- { [row] = { {s, e}, ... } } with 1-based cols, e exclusive — the shape
-- layout.content_line takes for emphasis. Follows codediff's own per-side
-- semantics (ui/inline.lua): the original side widens an empty tail on the
-- end line to one byte, the modified side drops it.
local function side_char_ranges(inner_changes, side, lines)
  local rows = {}
  for _, inner in ipairs(inner_changes or {}) do
    local r = inner[side]
    if r and not (r.start_line == r.end_line and r.start_col == r.end_col) then
      for row = r.start_line, math.min(r.end_line, #lines) do
        local text = lines[row]
        local s = row == r.start_line and utf16_col_to_byte_col(text, r.start_col) or 1
        local e -- 1-based inclusive end byte
        if row == r.end_line then
          e = utf16_col_to_byte_col(text, r.end_col) - 1
          if side == "original" then
            e = math.max(e, s)
          end
        else
          e = #text
        end
        s = math.max(1, math.min(s, #text + 1))
        e = math.min(e, #text)
        if e >= s then
          local row_ranges = rows[row]
          if not row_ranges then
            row_ranges = {}
            rows[row] = row_ranges
          end
          row_ranges[#row_ranges + 1] = { s = s, e = e + 1 }
        end
      end
    end
  end
  for _, ranges in pairs(rows) do
    table.sort(ranges, function(a, b)
      return a.s < b.s
    end)
  end
  return rows
end

--- Diff two hunk fragments with codediff's vscode-diff engine. Returns an
--- ordered list of { old_start, old_end, new_start, new_end } line changes
--- (1-based, end exclusive, fragment-relative) with per-row char emphasis in
--- old_emph/new_emph, or nil when the engine is unavailable or timed out
--- (the caller then falls back to the patch's own line runs).
function M.compute(frag_old, frag_new)
  local diff = get_diff()
  if not diff then
    return nil
  end
  local ok, result = pcall(diff.compute_diff, frag_old, frag_new, {
    max_computation_time_ms = 1000,
  })
  if not ok or type(result) ~= "table" or result.hit_timeout then
    return nil
  end

  local changes = {}
  for _, change in ipairs(result.changes or {}) do
    changes[#changes + 1] = {
      old_start = change.original.start_line,
      old_end = change.original.end_line,
      new_start = change.modified.start_line,
      new_end = change.modified.end_line,
      old_emph = side_char_ranges(change.inner_changes, "original", frag_old),
      new_emph = side_char_ranges(change.inner_changes, "modified", frag_new),
    }
  end
  return changes
end

return M
