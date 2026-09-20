local ansi = require('lib.ansi')
local blob = require('lib.blob')
local diffparse = require('lib.diffparse')
local engine = require('lib.engine')
local highlight = require('lib.highlight')
local langs = require('lib.langs')
local layout = require('lib.layout')
local passthrough = require('lib.passthrough')
local util = require('lib.util')

local M = {}

local LIMITS = {
  max_input_bytes = 2 * 1024 * 1024,
  max_file_section_lines = 20000,
  max_blob_bytes = 1024 * 1024,
  -- Above this, a side is highlighted from its hunk fragments instead of the
  -- full blob: a full-content treesitter parse is O(file bytes) per side no
  -- matter how little of the file the diff shows, and a half-megabyte file
  -- costs ~300ms per side before a single span is extracted.
  max_highlight_blob_bytes = 256 * 1024,
  max_highlighted_lines = 8000,
  -- Wall-clock ceiling on span extraction for the whole render; past it the
  -- remaining rows and files fall back to tints. Generous enough that only a
  -- render that would visibly stall lazygit ever hits it.
  max_highlight_ms = 1000,
  context_pad_rows = 1,
}

local uv = vim.uv

local function hl_expired(ctx)
  return uv.hrtime() > ctx.hl_deadline
end

-- Merge a padded 0-based row range into the tail of `ranges` (they are built
-- in ascending order, so only the last one can overlap).
local function push_range(ranges, s, e)
  local last = ranges[#ranges]
  if last and s <= last[2] + 1 then
    last[2] = math.max(last[2], e)
  else
    ranges[#ranges + 1] = { s, e }
  end
end

--- Merge the row ranges a file's hunks need on one side, with padding rows so
--- constructs straddling hunk edges are captured. 0-based inclusive ranges.
local function needed_ranges(hunks, side, pad)
  local ranges = {}
  for _, hunk in ipairs(hunks) do
    local start_row, count
    if side == 'old' then
      start_row, count = hunk.old_start - 1, hunk.old_count
    else
      start_row, count = hunk.new_start - 1, hunk.new_count
    end
    push_range(ranges, math.max(0, start_row - pad), start_row + math.max(count, 1) - 1 + pad)
  end
  return ranges
end

-- The inline layout renders context rows from the new side, so old-side spans
-- are only ever consulted for minus rows: restricting extraction to them makes
-- the old side's cost scale with the deletions rather than with everything the
-- hunks show, and a pure-addition file skips its old side entirely.
--
-- Ranges come from the engine's own change rows (hunk.changes), not the patch's
-- minus runs: the engine may realign a deletion to a row the patch never marked
-- as minus, and a row emitted outside the extracted ranges renders tinted but
-- unstyled.
--
-- `base` rebases a 1-based fragment row onto whatever is being highlighted: the
-- whole old file in full mode (hunk.old_start - 2), or the hunk's own fragment
-- in fragment mode (-1), where `max_row` also clamps to its last row.
local function push_minus_ranges(ranges, hunk, pad, base, max_row)
  for _, change in ipairs(hunk.changes) do
    if change.old_end > change.old_start then
      local e = base + change.old_end - 1 + pad
      push_range(
        ranges,
        math.max(0, base + change.old_start - pad),
        max_row and math.min(e, max_row) or e
      )
    end
  end
end

-- Compute treesitter spans for one side. In fragment mode the "file" is the
-- per-hunk reconstruction, so spans are stored on the hunk keyed by side.
-- `langs_by_side` differs between sides only for renames that change the
-- extension, where the old side is not the new side's language at all.
-- The side-by-side layout keeps whole-hunk old ranges: its left context cells
-- render from the old side, which the inline layout never does.
local function compute_spans(file, langs_by_side, ctx)
  local pad = LIMITS.context_pad_rows
  local minus_only = not ctx.split

  -- Extraction needs a language, at least one row to spend it on, and a
  -- deadline that has not passed. Stating that once keeps the four call sites
  -- below from restating it in three slightly different spellings.
  local function spans(lines, lang, ranges)
    if not lang or #ranges == 0 then
      return nil
    end
    if hl_expired(ctx) then
      ctx.hl_degraded = true
      return nil
    end
    local rows = highlight.line_spans(table.concat(lines, '\n'), lang, ranges, ctx.hl_deadline)
    -- line_spans stops collecting once the deadline passes, so a deadline that
    -- ran out during the call may have cost this side some of its rows.
    if hl_expired(ctx) then
      ctx.hl_degraded = true
    end
    return rows
  end

  if file.content_mode == 'full' then
    local sides = {}
    if file.need_old and langs_by_side.old then
      local ranges
      if minus_only then
        ranges = {}
        for _, hunk in ipairs(file.hunks) do
          push_minus_ranges(ranges, hunk, pad, hunk.old_start - 2)
        end
      else
        ranges = needed_ranges(file.hunks, 'old', pad)
      end
      sides.old = spans(file.old_lines, langs_by_side.old, ranges)
    end
    if file.need_new and langs_by_side.new then
      sides.new = spans(file.new_lines, langs_by_side.new, needed_ranges(file.hunks, 'new', pad))
    end
    return sides
  end

  for _, hunk in ipairs(file.hunks) do
    if langs_by_side.old then
      local max_row = math.max(#hunk.frag_old - 1, 0)
      local ranges
      if minus_only then
        ranges = {}
        push_minus_ranges(ranges, hunk, pad, -1, max_row)
      else
        ranges = { { 0, max_row } }
      end
      hunk.frag_old_spans = spans(hunk.frag_old, langs_by_side.old, ranges)
    end
    hunk.frag_new_spans =
      spans(hunk.frag_new, langs_by_side.new, { { 0, math.max(#hunk.frag_new - 1, 0) } })
  end
  return nil
end

-- Treesitter spans for fragment row `row` (1-based) on `side`, or nil when
-- highlighting is off for the file. `text` and `lnum` are the row's own text
-- and absolute line number, both already derived by the cell being built.
local function spans_for(file, hunk, sides, side, row, text, lnum)
  if file.content_mode == 'full' then
    local src_lines = side == 'old' and file.old_lines or file.new_lines
    -- Sanity guard: if the acquired content disagrees with the diff
    -- (reversed diffs, odd hashes), render the diff's own text unstyled.
    if src_lines and src_lines[lnum] == text then
      local src_spans = sides and sides[side]
      return src_spans and src_spans[lnum - 1]
    end
    return nil
  end
  local frag_spans = side == 'old' and hunk.frag_old_spans or hunk.frag_new_spans
  return frag_spans and frag_spans[row - 1]
end

-- Walk a hunk's rows in order, handing each run to the layout that draws it.
-- Between changes the two sides' pointers advance in step, which is both the
-- pairing the side-by-side layout draws and the numbering the inline layout
-- prints -- so the bookkeeping lives here rather than once per layout.
local function walk_hunk(hunk, emit_context, emit_change)
  local old_ptr, new_ptr = 1, 1
  local function context_rows(count)
    for _ = 1, count do
      emit_context(old_ptr, new_ptr)
      old_ptr, new_ptr = old_ptr + 1, new_ptr + 1
    end
  end
  for _, change in ipairs(hunk.changes) do
    context_rows(change.new_start - new_ptr)
    emit_change(change)
    old_ptr, new_ptr = change.old_end, change.new_end
  end
  context_rows(#hunk.frag_new - new_ptr + 1)
end

-- Inline layout (codediff.nvim's inline view): deleted blocks render above
-- their inserted blocks, context lines stay undecorated.
local function render_hunk_inline(out, hunk, cell, ctx)
  local function emit(c, old_no, new_no)
    layout.content_line(out, c, old_no, new_no, ctx.cols, ctx.num_w)
  end

  -- Context rows render from the new side, so their old-side number is not on
  -- the cell and comes from the walker's old pointer instead.
  local old_base = hunk.old_start - 1
  walk_hunk(hunk, function(old_row, new_row)
    local c = cell('new', new_row, 'context')
    emit(c, old_base + old_row, c.lnum)
  end, function(change)
    for row = change.old_start, change.old_end - 1 do
      local c = cell('old', row, 'minus', change.old_emph[row])
      emit(c, c.lnum, nil)
    end
    for row = change.new_start, change.new_end - 1 do
      local c = cell('new', row, 'plus', change.new_emph[row])
      emit(c, nil, c.lnum)
    end
  end)
end

-- Side-by-side layout (codediff.nvim's default view): original left,
-- modified right, absent lines shown as filler.
local function render_hunk_split(out, hunk, cell, ctx)
  local function row(left, right)
    layout.split_line(out, left, right, ctx.cols, ctx.num_w)
  end

  walk_hunk(hunk, function(old_row, new_row)
    row(cell('old', old_row, 'context'), cell('new', new_row, 'context'))
  end, function(change)
    local old_n = change.old_end - change.old_start
    local new_n = change.new_end - change.new_start
    for k = 0, math.max(old_n, new_n) - 1 do
      local left = k < old_n
          and cell('old', change.old_start + k, 'minus', change.old_emph[change.old_start + k])
        or { filler = true }
      local right = k < new_n
          and cell('new', change.new_start + k, 'plus', change.new_emph[change.new_start + k])
        or { filler = true }
      row(left, right)
    end
  end)
end

local function render_hunk(out, file, hunk, sides, langs_by_side, ctx)
  local function cell(side, row, line_type, emph)
    local frag = side == 'old' and hunk.frag_old or hunk.frag_new
    local text = frag[row]
    -- Absolute line number of this row on its own side.
    local lnum = (side == 'old' and hunk.old_start or hunk.new_start) + row - 1
    return {
      text = text or '',
      spans = langs_by_side[side] and spans_for(file, hunk, sides, side, row, text, lnum) or nil,
      line_type = line_type,
      emph = emph,
      lnum = lnum,
    }
  end

  if ctx.split then
    render_hunk_split(out, hunk, cell, ctx)
  else
    render_hunk_inline(out, hunk, cell, ctx)
  end

  -- The flag only ever marks the EOF line of a side; the engine may reorder
  -- lines, so a single trailing note keeps it attached to the right hunk.
  for _, hline in ipairs(hunk.lines) do
    if hline.no_newline then
      out[#out + 1] = layout.note_row('\\ no newline at end of file')
      break
    end
  end
end

local function render_file(file, ctx)
  if file.is_combined then
    return passthrough.render_combined(file)
  end

  local out = {}
  -- A deleted file has no new side at all, so this falls through to the old
  -- path without needing to know that (see parse_extended_header).
  local display_path = file.new_path or file.old_path or '?'

  if file.renamed_from and file.renamed_to then
    out[#out + 1] = layout.note_row('renamed: ' .. file.renamed_from .. ' => ' .. file.renamed_to)
  end
  if file.old_mode and file.new_mode and not file.is_new and not file.is_deleted then
    out[#out + 1] = layout.note_row('mode changed: ' .. file.old_mode .. ' => ' .. file.new_mode)
  end
  if file.is_binary then
    out[#out + 1] = layout.note_row('binary: ' .. display_path)
    return table.concat(out)
  end
  if #file.hunks == 0 then
    if #out == 0 and (file.is_new or file.is_deleted) then
      out[#out + 1] = layout.note_row(
        (file.is_new and 'new empty file: ' or 'deleted empty file: ') .. display_path
      )
    end
    return table.concat(out)
  end

  -- Budget: once the global highlighting budget is spent, the remaining files
  -- render with tints only. Oversized sections were already classified plain
  -- by blob.acquire, which owns content_mode. The wall-clock deadline is not
  -- consulted here but where spans are extracted (compute_spans), which is the
  -- one place that can tell a file the deadline cost its highlighting from one
  -- that never had a language to highlight.
  local langs_by_side = {}
  if file.content_mode ~= 'plain' and ctx.budget > 0 then
    local full = file.content_mode == 'full'
    langs_by_side.new = langs.lang_for(
      display_path,
      full and (file.need_new and file.new_lines or file.old_lines) or nil
    )
    -- A rename may change the extension, and then the old side is a different
    -- language entirely (script.sh => script.py).
    local old_path = file.old_path or display_path
    if old_path == display_path then
      langs_by_side.old = langs_by_side.new
    else
      langs_by_side.old = langs.lang_for(old_path, full and file.old_lines or nil)
    end
  end

  -- Both the engine and the fallback renderer consume the per-hunk fragments.
  -- Changes are computed before span extraction so the old-side ranges can
  -- follow the rows the engine actually emits (see push_minus_ranges).
  local max_lnum = 0
  for _, hunk in ipairs(file.hunks) do
    hunk.frag_old = diffparse.hunk_fragment(hunk, 'old')
    hunk.frag_new = diffparse.hunk_fragment(hunk, 'new')
    local last = math.max(hunk.old_start + hunk.old_count, hunk.new_start + hunk.new_count) - 1
    max_lnum = math.max(max_lnum, last)
    local changes = file.content_mode ~= 'plain' and engine.compute(hunk.frag_old, hunk.frag_new)
      or nil
    if not changes or #changes == 0 then
      -- No engine, or it sees no difference at all (a CRLF-only change:
      -- fragments are CR-stripped); the patch's own runs are the only truthful
      -- rendering.
      changes = engine.patch_changes(hunk)
    end
    hunk.changes = changes
  end

  local sides = nil
  if langs_by_side.old or langs_by_side.new then
    ctx.budget = ctx.budget - file.hunk_lines
    sides = compute_spans(file, langs_by_side, ctx)
  end

  ctx.num_w = layout.number_width(max_lnum)
  for i, hunk in ipairs(file.hunks) do
    -- Blank separator so a header reads as belonging to the section below
    -- it, not the one above (the file's first header sticks to its notes;
    -- the file-level separator is added by M.render).
    if i > 1 then
      out[#out + 1] = '\n'
    end
    -- A pure-deletion hunk has new_count == 0 and a new_start pointing at the
    -- line *before* it (0 for a whole-file delete), so anchor on the old side.
    local start_lnum = hunk.new_count > 0 and hunk.new_start or hunk.old_start
    out[#out + 1] = layout.hunk_header(display_path, start_lnum, hunk.heading, ctx.cols)
    render_hunk(out, file, hunk, sides, langs_by_side, ctx)
    hunk.frag_old, hunk.frag_new, hunk.changes = nil, nil, nil
    hunk.frag_old_spans, hunk.frag_new_spans = nil, nil
  end

  return table.concat(out)
end

--- Render raw git diff/show output to ANSI, returning the whole document.
--- All-or-nothing by contract: a caller that fails must be able to fall back to
--- the raw diff, and appending it behind a half-written render would show the
--- same hunks twice. opts:
---   cwd    repo directory for blob lookups
---   cols   target width (LAZYGIT_COLUMNS)
---   layout "side-by-side" for the split view; anything else renders inline
---   force_fragment  skip git blob lookups (repo-independent fixtures)
--- Returns the document plus a cacheable flag: false when the render read the
--- worktree (an unstaged diff), whose files can change under an unchanged diff,
--- and false when the wall-clock highlight deadline degraded the output --
--- caching would replay a transiently slow first render (cold parsers, query
--- compilation) as tint-only for the daemon's lifetime, while a warm re-render
--- may finish well inside the budget. "Degraded" is recorded where a span
--- extraction was actually skipped or cut short, not read off the clock at the
--- end: a render that highlighted everything and then spent its time emitting
--- rows is exactly the expensive one the cache exists for.
function M.render(input, opts)
  if #input > LIMITS.max_input_bytes then
    return input, false
  end

  input = ansi.strip_git_colors(input)
  local lines = util.split_lines(input)
  local blocks = diffparse.parse(lines)

  local files = {}
  for _, block in ipairs(blocks) do
    if block.kind == 'file' then
      files[#files + 1] = block
    end
  end
  local looks_like_git = #files > 0 or (lines[1] and lines[1]:match('^commit %x+'))
  if not looks_like_git then
    return input, false
  end

  local worktree_dep = blob.acquire(files, opts.cwd, LIMITS, opts.force_fragment)

  local ctx = {
    cols = opts.cols or 120,
    budget = LIMITS.max_highlighted_lines,
    split = opts.layout == 'side-by-side',
    hl_deadline = uv.hrtime() + LIMITS.max_highlight_ms * 1e6,
    hl_degraded = false, -- set once the deadline costs any row its spans
    num_w = nil, -- line-number gutter digits, set per file
  }
  local out = {}
  for _, block in ipairs(blocks) do
    local chunk
    if block.kind == 'raw' then
      chunk = passthrough.render_raw(block.lines, ctx.cols)
    else
      chunk = render_file(block, ctx)
    end
    if #chunk > 0 then
      -- Blank separator between sections; raw blocks keep git's own spacing.
      if block.kind == 'file' and #out > 0 then
        out[#out + 1] = '\n'
      end
      out[#out + 1] = chunk
    end
  end
  return table.concat(out), not worktree_dep and not ctx.hl_degraded
end

return M
