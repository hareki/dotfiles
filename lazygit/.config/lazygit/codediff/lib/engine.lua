local M = {}

-- codediff.nvim is required lazily and behind pcall: a missing or broken
-- plugin must only cost the changed words their emphasis, never break the
-- render. nil: not tried yet, false: unavailable. require memoizes successful
-- loads itself; the false is what keeps a broken plugin from being re-pcall'd
-- once per change for the daemon's lifetime.
local diff_engine = nil

local function diff_module()
  if diff_engine == nil then
    local ok, mod = pcall(require, 'codediff.core.diff')
    diff_engine = ok and mod or false
  end
  return diff_engine or nil
end

-- Mirrors codediff's utf16_col_to_byte_col (ui/inline.lua): engine columns are
-- 1-based UTF-16 code units, end-exclusive. codediff reaches the conversion
-- through its own pre-0.11 compat shim; on the versions this renderer targets
-- (vim.hl.priorities in lib/highlight.lua is already 0.11+) that shim is
-- exactly this builtin, so call it rather than a private module of another
-- plugin. pcall: strict indexing rejects a column past the end of the line.
local function utf16_col_to_byte_col(line, utf16_col)
  if not line or utf16_col <= 1 then
    return utf16_col
  end
  local ok, byte_idx = pcall(vim.str_byteindex, line, 'utf-16', utf16_col - 1, true)
  if ok then
    return byte_idx + 1
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

local function by_start(a, b)
  return a.s < b.s
end

-- Split one side of the char-level inner changes into per-row byte ranges:
-- { [row] = { {s, e}, ... } } with 1-based cols, e exclusive: the shape
-- layout.content_line takes for emphasis. Follows codediff's own per-side
-- semantics (ui/inline.lua): the original side widens an empty tail on the
-- end line to one byte, the modified side drops it. `lines` are the rows the
-- engine was given, and `offset` places them in the hunk fragment.
local function side_char_ranges(inner_changes, side, lines, offset)
  local rows = {}
  for _, inner in ipairs(inner_changes) do
    local r = inner[side]
    if r and not (r.start_line == r.end_line and r.start_col == r.end_col) then
      for row = r.start_line, math.min(r.end_line, #lines) do
        local text = lines[row]
        local s = row == r.start_line and utf16_col_to_byte_col(text, r.start_col) or 1
        local e -- 1-based inclusive end byte
        if row == r.end_line then
          e = utf16_col_to_byte_col(text, r.end_col) - 1
          if side == 'original' then
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
          local row_ranges = rows[row + offset]
          if not row_ranges then
            row_ranges = {}
            rows[row + offset] = row_ranges
          end
          row_ranges[#row_ranges + 1] = { s = s, e = e + 1 }
        end
      end
    end
  end
  for _, ranges in pairs(rows) do
    table.sort(ranges, by_start)
  end
  return rows
end

-- Fill in a change's char emphasis by running codediff's vscode-diff engine
-- over the change's own rows, `old_rows` and `new_rows`. Left without any when
-- the engine is unavailable or timed out, or sees no difference at all (a
-- CRLF-only change: the rows are CR-stripped): they are still drawn as changed,
-- just without words picked out.
local function emphasize(change, old_rows, new_rows)
  local diff = diff_module()
  if not diff then
    return
  end
  local ok, result = pcall(diff.compute_diff, old_rows, new_rows, {
    max_computation_time_ms = 1000,
  })
  if not ok or type(result) ~= 'table' or result.hit_timeout then
    return
  end

  local inner_changes = {}
  for _, line_change in ipairs(result.changes or {}) do
    vim.list_extend(inner_changes, line_change.inner_changes or {})
  end
  change.old_emph = side_char_ranges(inner_changes, 'original', old_rows, change.old_start - 1)
  change.new_emph = side_char_ranges(inner_changes, 'modified', new_rows, change.new_start - 1)
end

--- A hunk's line changes as the patch has them: each minus run paired with the
--- plus run that follows it, as an ordered list of { old_start, old_end,
--- new_start, new_end } (1-based, end exclusive, fragment-relative) with
--- per-row char emphasis in old_emph/new_emph.
---
--- The rows come from the patch rather than from the engine because they are
--- what lazygit stages: the engine is free to slide a change along lines that
--- read the same (a blank line or a brace on either end of a deleted block),
--- and a row drawn as changed would then not be the line that staging it
--- stages. The engine still picks out the changed words, within each run,
--- unless `with_emphasis` is unset (plain mode: an oversized file).
function M.changes(hunk, with_emphasis)
  local lines = hunk.lines
  local changes = {}
  local i, old_row, new_row = 1, 0, 0
  while i <= #lines do
    if lines[i].origin == ' ' then
      old_row, new_row, i = old_row + 1, new_row + 1, i + 1
    else
      local old_rows, new_rows = {}, {}
      while i <= #lines and lines[i].origin == '-' do
        old_rows[#old_rows + 1], i = lines[i].text, i + 1
      end
      while i <= #lines and lines[i].origin == '+' do
        new_rows[#new_rows + 1], i = lines[i].text, i + 1
      end
      local minus_n, plus_n = #old_rows, #new_rows
      local change = {
        old_start = old_row + 1,
        old_end = old_row + 1 + minus_n,
        new_start = new_row + 1,
        new_end = new_row + 1 + plus_n,
        old_emph = {},
        new_emph = {},
      }
      -- A run with only one side has nothing to compare its words against.
      if with_emphasis and minus_n > 0 and plus_n > 0 then
        emphasize(change, old_rows, new_rows)
      end
      changes[#changes + 1] = change
      old_row, new_row = old_row + minus_n, new_row + plus_n
    end
  end
  return changes
end

return M
