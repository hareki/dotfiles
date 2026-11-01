local M = {}

-- Ceiling on the engine's time for one change's words. The engine runs on the
-- same clock as span extraction, and a rewrite it cannot finish in time would
-- otherwise spend the render's whole highlighting budget on emphasis; an ordinary
-- change takes a few milliseconds, a large one tens.
local MAX_EMPHASIS_MS = 100

-- Behind pcall: a missing or broken codediff.nvim must only cost the changed
-- words their emphasis, never break the render. Every entry point runs
-- bootstrap.setup(), which puts the plugin on the rtp, before it requires this
-- module.
local has_diff, diff = pcall(require, 'codediff.core.diff')

-- Mirrors codediff's utf16_col_to_byte_col (ui/inline.lua): engine columns are
-- 1-based UTF-16 code units, end-exclusive. Not strict: a column past the end of
-- the line clamps to the end.
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

-- Split one side of the char-level inner changes into per-row byte ranges,
-- written into `rows`: { [row] = { {s, e}, ... } } with 1-based cols, e exclusive:
-- the shape layout.content_line takes for emphasis, and in the start order it
-- relies on, which is the order the engine reports its changes in. Follows
-- codediff's own per-side semantics (ui/inline.lua): the original side widens an
-- empty tail on the end line to one byte, the modified side drops it. `lines` are
-- the rows the engine was given, and `offset` places them among the side's rows.
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
end

-- Fill in a change's char emphasis by running codediff's vscode-diff engine
-- over the change's own rows. Left without any when the engine is unavailable or
-- timed out, or sees no difference at all (a CRLF-only change: the rows are
-- CR-stripped): they are still drawn as changed, just without words picked out.
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

--- Pick out the changed words within each of a hunk's changes. A change with
--- only one side has nothing to compare its words against.
function M.emphasize(hunk)
  for _, change in ipairs(hunk.changes) do
    if change.old_end > change.old_start and change.new_end > change.new_start then
      emphasize(hunk, change)
    end
  end
end

return M
