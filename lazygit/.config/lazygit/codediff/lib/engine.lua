local M = {}

-- Per change, so one rewrite can't spend the render's whole highlighting budget on emphasis.
local MAX_EMPHASIS_MS = 100

-- Behind pcall: a missing or broken codediff.nvim may only cost the changed words their emphasis.
local has_diff, diff = pcall(require, 'codediff.core.diff')

-- codediff's utf16_col_to_byte_col (ui/inline.lua) for 1-based UTF-16 columns, clamped at the end.
local function utf16_col_to_byte_col(line, utf16_col)
  if utf16_col <= 1 then
    return utf16_col
  end
  return vim.str_byteindex(line, 'utf-16', utf16_col - 1, false) + 1
end

-- Byte index of the last byte of the UTF-8 sequence covering byte `i`.
local function char_last_byte(line, i)
  if i < 1 or i > #line then
    return i
  end
  return i + vim.str_utf_end(line, i)
end

-- One side's inner changes as 1-based, end-exclusive byte ranges per side row (`offset` past
-- `lines`' rows), in start order. Like codediff, only the original side widens an empty tail.
local function side_char_ranges(rows, inner_changes, side, lines, offset)
  for _, inner in ipairs(inner_changes) do
    local r = inner[side]
    if not (r.start_line == r.end_line and r.start_col == r.end_col) then
      for row = r.start_line, math.min(r.end_line, #lines) do
        local text = lines[row]
        local s = row == r.start_line and utf16_col_to_byte_col(text, r.start_col) or 1
        local e -- 1-based inclusive end byte
        if row == r.end_line then
          e = utf16_col_to_byte_col(text, r.end_col) - 1
          if side == 'original' then
            -- A whole character, not a byte: a range ending mid-sequence puts an SGR escape in it.
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
end

-- Fill in a change's char emphasis from codediff's engine over its rows. None when the engine is
-- unavailable, times out or sees no change (a CRLF-only one): the rows still show as changed.
local function emphasize(hunk, change)
  if not has_diff then
    return
  end
  local old_rows = vim.list_slice(hunk.old.rows, change.old_start, change.old_end - 1)
  local new_rows = vim.list_slice(hunk.new.rows, change.new_start, change.new_end - 1)
  local ok, result = pcall(diff.compute_diff, old_rows, new_rows, {
    max_computation_time_ms = MAX_EMPHASIS_MS,
  })
  if not (ok and result) or result.hit_timeout then
    return
  end

  local inner_changes = {}
  for _, line_change in ipairs(result.changes) do
    vim.list_extend(inner_changes, line_change.inner_changes)
  end
  side_char_ranges(hunk.old.emph, inner_changes, 'original', old_rows, change.old_start - 1)
  side_char_ranges(hunk.new.emph, inner_changes, 'modified', new_rows, change.new_start - 1)
end

--- Pick out the changed words in each change that has both sides to compare.
function M.emphasize(hunk)
  for _, change in ipairs(hunk.changes) do
    if change.old_end > change.old_start and change.new_end > change.new_start then
      emphasize(hunk, change)
    end
  end
end

return M
