local M = {}

-- codediff.nvim is required lazily and behind pcall: a missing or broken
-- plugin must degrade to the patch's own line runs, never break the render.
local loaded = {}

local function lazy_require(name)
  local mod = loaded[name]
  if mod == nil then
    local ok, result = pcall(require, name)
    mod = ok and result or false
    loaded[name] = mod
  end
  return mod or nil
end

-- Mirrors codediff's utf16_col_to_byte_col (ui/inline.lua): engine columns are
-- 1-based UTF-16 code units, end-exclusive.
local function utf16_col_to_byte_col(line, utf16_col)
  if not line or utf16_col <= 1 then
    return utf16_col
  end
  local compat = lazy_require("codediff.core.compat")
  if compat then
    local ok, byte_idx = pcall(compat.str_byteindex_utf16, line, utf16_col - 1)
    if ok then
      return byte_idx + 1
    end
  end
  return utf16_col
end

-- Byte index of the last byte of the UTF-8 sequence covering byte `i`.
local function char_last_byte(line, i)
  if i < 1 or i > #line then
    return i
  end
  local ok, off = pcall(vim.str_utf_end, line, i)
  return ok and (i + off) or i
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
            -- Widen an empty tail marker to a whole character, not a single
            -- byte: a range ending mid-sequence makes the renderer cut the
            -- character in two and emit an SGR escape between its bytes.
            e = math.max(e, char_last_byte(text, s))
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
  local diff = lazy_require("codediff.core.diff")
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

--- The same change list derived from the patch's own line runs: each minus run
--- pairs with the plus run that follows it. Used when the engine is unavailable
--- (plugin missing, timeout, oversized file) or when it reports no difference at
--- all (a CRLF-only change: fragments are CR-stripped), so every renderer gets
--- one shape to consume instead of its own fallback path.
function M.patch_changes(hunk)
  local lines = hunk.lines
  local changes = {}
  local i, old_row, new_row = 1, 0, 0
  while i <= #lines do
    if lines[i].origin == " " then
      old_row, new_row, i = old_row + 1, new_row + 1, i + 1
    else
      local minus_n, plus_n = 0, 0
      while i <= #lines and lines[i].origin == "-" do
        minus_n, i = minus_n + 1, i + 1
      end
      while i <= #lines and lines[i].origin == "+" do
        plus_n, i = plus_n + 1, i + 1
      end
      changes[#changes + 1] = {
        old_start = old_row + 1,
        old_end = old_row + 1 + minus_n,
        new_start = new_row + 1,
        new_end = new_row + 1 + plus_n,
        old_emph = {},
        new_emph = {},
      }
      old_row, new_row = old_row + minus_n, new_row + plus_n
    end
  end
  return changes
end

return M
