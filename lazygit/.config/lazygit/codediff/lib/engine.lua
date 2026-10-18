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
  if utf16_col <= 1 then
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
-- over the change's own rows for at most `max_ms`. Left without any when the
-- engine is unavailable or timed out, or sees no difference at all (a CRLF-only
-- change: the rows are CR-stripped): they are still drawn as changed, just
-- without words picked out.
local function emphasize(change, max_ms)
  local diff = diff_module()
  if not diff then
    return
  end
  local ok, result = pcall(diff.compute_diff, change.old_rows, change.new_rows, {
    max_computation_time_ms = max_ms,
  })
  if not ok or type(result) ~= 'table' or result.hit_timeout then
    return
  end

  local inner_changes = {}
  for _, line_change in ipairs(result.changes or {}) do
    vim.list_extend(inner_changes, line_change.inner_changes or {})
  end
  change.old_emph =
    side_char_ranges(inner_changes, 'original', change.old_rows, change.old_start - 1)
  change.new_emph =
    side_char_ranges(inner_changes, 'modified', change.new_rows, change.new_start - 1)
end

--- Pick out the changed words within each of a hunk's changes
--- (diffparse.hunk_rows), giving the engine at most `max_ms` for any one of
--- them. A change with only one side has nothing to compare its words against.
function M.emphasize(changes, max_ms)
  for _, change in ipairs(changes) do
    if #change.old_rows > 0 and #change.new_rows > 0 then
      emphasize(change, max_ms)
    end
  end
end

return M
