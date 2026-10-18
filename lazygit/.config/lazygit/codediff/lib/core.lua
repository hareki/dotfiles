local ansi = require('lib.ansi')
local blob = require('lib.blob')
local diffparse = require('lib.diffparse')
local engine = require('lib.engine')
local highlight = require('lib.highlight')
local langs = require('lib.langs')
local layout = require('lib.layout')
local osc1717 = require('lib.osc1717')
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
  -- Ceiling on the diff engine's time for one change's words. The engine runs
  -- on the same clock as span extraction, and a rewrite it cannot finish in
  -- time would otherwise spend the render's whole highlighting budget on
  -- emphasis; an ordinary change takes a few milliseconds, a large one tens.
  max_emphasis_ms = 100,
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
-- Ranges come from the change rows the layouts draw (hunk.changes): a row
-- emitted outside the extracted ranges renders tinted but unstyled.
--
-- `first_row` is where the hunk's fragment row 1 sits in whatever is being
-- highlighted (hunk.span_base.old, see compute_spans).
local function push_minus_ranges(ranges, hunk, pad, first_row)
  for _, change in ipairs(hunk.changes) do
    if change.old_end > change.old_start then
      push_range(
        ranges,
        math.max(0, first_row + change.old_start - 1 - pad),
        first_row + change.old_end - 2 + pad
      )
    end
  end
end

-- A fragment is highlighted on its own, so its first row is row 0 on both sides.
local FRAGMENT_BASE = { old = 0, new = 0 }

-- Compute treesitter spans for both sides of a file, and leave each hunk the
-- rows its cells read them from: hunk.spans[side], where the hunk's fragment
-- row 1 sits at index hunk.span_base[side]. In full mode those are the side's
-- whole file, shared by every hunk -- blob.acquire found the content and the
-- patch to agree, so a fragment row maps onto its parsed line by its offset
-- alone. In fragment mode they are the hunk's own reconstruction.
-- `langs_by_side` differs between sides only for renames that change the
-- extension, where the old side is not the new side's language at all.
-- The side-by-side layout keeps whole-hunk old ranges: its left context cells
-- render from the old side, which the inline layout never does.
local function compute_spans(file, langs_by_side, ctx)
  local pad = LIMITS.context_pad_rows
  local minus_only = not ctx.split

  -- Extraction needs a language, at least one row to spend it on, and a
  -- deadline that has not passed. Stating that once keeps the call sites below
  -- from restating it.
  local function spans(lines, lang, ranges)
    if not lang or #ranges == 0 then
      return nil
    end
    if hl_expired(ctx) then
      ctx.hl_degraded = true
      return nil
    end
    local rows, cut_short =
      highlight.line_spans(table.concat(lines, '\n'), lang, ranges, ctx.hl_deadline)
    if cut_short then
      ctx.hl_degraded = true
    end
    return rows
  end

  if file.content_mode == 'full' then
    local sides = {}
    for _, hunk in ipairs(file.hunks) do
      hunk.spans = sides
      hunk.span_base = { old = hunk.old_start - 1, new = hunk.new_start - 1 }
    end
    if file.need_old then
      local ranges
      if minus_only then
        ranges = {}
        for _, hunk in ipairs(file.hunks) do
          push_minus_ranges(ranges, hunk, pad, hunk.span_base.old)
        end
      else
        ranges = needed_ranges(file.hunks, 'old', pad)
      end
      sides.old = spans(file.old_lines, langs_by_side.old, ranges)
    end
    if file.need_new then
      sides.new = spans(file.new_lines, langs_by_side.new, needed_ranges(file.hunks, 'new', pad))
    end
    return
  end

  for _, hunk in ipairs(file.hunks) do
    local ranges
    if minus_only then
      ranges = {}
      push_minus_ranges(ranges, hunk, pad, FRAGMENT_BASE.old)
    else
      ranges = { { 0, math.max(#hunk.frag_old - 1, 0) } }
    end
    local old_spans = spans(hunk.frag_old, langs_by_side.old, ranges)
    hunk.spans = {
      old = old_spans,
      new = spans(hunk.frag_new, langs_by_side.new, { { 0, math.max(#hunk.frag_new - 1, 0) } }),
    }
    hunk.span_base = FRAGMENT_BASE
  end
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
    local right = cell('new', new_row, 'context')
    -- The left cell's record names the same line and stays in effect to the
    -- row's end.
    right.record = nil
    row(cell('old', old_row, 'context'), right)
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

local function render_hunk(out, hunk, ctx)
  local function cell(side, row, line_type, emph)
    -- Spans, when this side has any (see compute_spans).
    local rows = hunk.spans and hunk.spans[side]
    return {
      text = (side == 'old' and hunk.frag_old or hunk.frag_new)[row],
      spans = rows and rows[hunk.span_base[side] + row - 1],
      line_type = line_type,
      emph = emph,
      -- Absolute line number of this row on its own side.
      lnum = (side == 'old' and hunk.old_start or hunk.new_start) + row - 1,
      record = hunk.records and hunk.records[side][row],
    }
  end

  if ctx.split then
    render_hunk_split(out, hunk, cell, ctx)
  else
    render_hunk_inline(out, hunk, cell, ctx)
  end

  if hunk.no_newline then
    out[#out + 1] = layout.note_row('\\ no newline at end of file')
  end
end

local function render_file(file, ctx)
  local out = {}
  -- A deleted file has no new side at all, so this falls through to the old
  -- path without needing to know that (see parse_extended_header).
  local patch_path = file.new_path or file.old_path
  local display_path = patch_path or '?'

  -- The OSC 1717 records for this file's rows, nil when the render wasn't asked
  -- for them (or can't carry the path).
  local record = ctx.metadata and patch_path and osc1717.recorder(patch_path) or nil

  -- The notes stand in for the file header git's patch opens with.
  local file_record = record and record('f')
  local function note(text)
    out[#out + 1] = layout.note_row(text, file_record)
  end
  if file.renamed_from and file.renamed_to then
    note('renamed: ' .. file.renamed_from .. ' => ' .. file.renamed_to)
  end
  if file.old_mode and file.new_mode and not file.is_new and not file.is_deleted then
    note('mode changed: ' .. file.old_mode .. ' => ' .. file.new_mode)
  end
  if file.is_binary then
    note('binary: ' .. display_path)
    return table.concat(out)
  end
  if #file.hunks == 0 then
    if #out == 0 and (file.is_new or file.is_deleted) then
      note((file.is_new and 'new empty file: ' or 'deleted empty file: ') .. display_path)
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

  -- Changes are laid out before span extraction so the old-side ranges can
  -- follow the minus rows (see push_minus_ranges).
  local max_lnum = 0
  for _, hunk in ipairs(file.hunks) do
    hunk.frag_old, hunk.frag_new, hunk.changes = diffparse.hunk_rows(hunk)
    -- Plain mode (an oversized section) draws the changes without their words.
    if file.content_mode ~= 'plain' then
      engine.emphasize(hunk.changes, LIMITS.max_emphasis_ms)
    end
    local last = math.max(hunk.old_start + hunk.old_count, hunk.new_start + hunk.new_count) - 1
    max_lnum = math.max(max_lnum, last)
  end

  if langs_by_side.old or langs_by_side.new then
    ctx.budget = ctx.budget - file.hunk_lines
    compute_spans(file, langs_by_side, ctx)
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
    -- The record carries git's own @@ +number even so: lazygit numbers a hunk
    -- header by its new side.
    out[#out + 1] = layout.hunk_header(
      display_path,
      start_lnum,
      hunk.heading,
      ctx.cols,
      record and record('h', hunk.new_start)
    )
    hunk.records = record and osc1717.hunk_records(hunk, record)
    render_hunk(out, hunk, ctx)
    hunk.frag_old, hunk.frag_new, hunk.changes, hunk.records = nil, nil, nil, nil
    hunk.spans, hunk.span_base = nil, nil
  end

  return table.concat(out)
end

--- Render raw git diff/show output to ANSI, returning the whole document.
--- All-or-nothing by contract: a caller that fails must be able to fall back to
--- the raw diff, and appending it behind a half-written render would show the
--- same hunks twice. opts:
---   cwd    repo directory for blob lookups
---   cols   target width (COLUMNS)
---   layout "side-by-side" for the split view; anything else renders inline
---   force_fragment  skip git blob lookups (repo-independent fixtures)
---   metadata  put an OSC 1717 record ahead of each row lazygit can act on
---             (see lib/osc1717.lua)
--- Returns the document, whether it may be cached, and the worktree files the
--- render consulted (blob.acquire), which a cached copy is only good for while
--- they are unchanged (blob.unchanged). It may not be cached when the
--- wall-clock highlight deadline degraded the output -- caching would replay a
--- transiently slow first render (cold parsers, query compilation) as
--- tint-only for the daemon's lifetime, while a warm re-render may finish well
--- inside the budget. "Degraded" is recorded where a span extraction was
--- actually skipped or cut short, not read off the clock at the end: a render
--- that highlighted everything and then spent its time emitting rows is
--- exactly the expensive one the cache exists for.
function M.render(input, opts)
  if #input > LIMITS.max_input_bytes then
    return input, false
  end

  input = ansi.strip_git_colors(input)
  local lines = util.split_lines(input)
  local blocks = diffparse.parse(lines)

  -- Git's output rather than arbitrary text piped through: it has a diff
  -- section, or opens with the commit line of a `git show` that has none.
  local files = {}
  local looks_like_git = lines[1] ~= nil and diffparse.commit_line(lines[1]) ~= nil
  for _, block in ipairs(blocks) do
    if block.kind == 'file' then
      files[#files + 1] = block
    end
    looks_like_git = looks_like_git or block.kind ~= 'raw'
  end
  if not looks_like_git then
    return input, false
  end

  local consulted = blob.acquire(files, opts.cwd, LIMITS, opts.force_fragment)

  local ctx = {
    cols = opts.cols or 120,
    budget = LIMITS.max_highlighted_lines,
    split = opts.layout == 'side-by-side',
    metadata = opts.metadata,
    hl_deadline = uv.hrtime() + LIMITS.max_highlight_ms * 1e6,
    hl_degraded = false, -- set once the deadline costs any row its spans
    num_w = nil, -- line-number gutter digits, set per file
  }
  local out = {}
  for _, block in ipairs(blocks) do
    local chunk
    if block.kind == 'raw' then
      chunk = passthrough.render_raw(block.lines, ctx.cols)
    elseif block.kind == 'combined' then
      chunk = passthrough.render_combined(block)
    else
      chunk = render_file(block, ctx)
    end
    if #chunk > 0 then
      -- Blank separator between sections; raw blocks keep git's own spacing.
      if block.kind ~= 'raw' and #out > 0 then
        out[#out + 1] = '\n'
      end
      out[#out + 1] = chunk
    end
  end
  return table.concat(out), not ctx.hl_degraded, consulted
end

return M
