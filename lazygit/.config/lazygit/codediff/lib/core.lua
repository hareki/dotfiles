local ansi = require('lib.ansi')
local blob = require('lib.blob')
local buffer = require('string.buffer')
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
  max_highlighted_lines = 8000,
  -- Wall-clock ceiling on span extraction for the whole render; past it the
  -- remaining rows and files fall back to tints. Generous enough that only a
  -- render that would visibly stall lazygit ever hits it.
  max_highlight_ms = 1000,
}

-- The inline layout renders context rows from the new side, so old-side spans
-- are only ever consulted for minus rows: restricting extraction to them makes
-- the old side's cost scale with the deletions rather than with everything the
-- hunks show, and a pure-addition file skips its old side entirely. The
-- side-by-side layout draws its left context cells from the old side, so it
-- keeps whole hunks.
--
-- 0-based and end-exclusive, with `first_row` where the hunk's row 1 sits in
-- whatever is being highlighted. No padding is needed for a construct straddling
-- a hunk's edge: a query window reports every node that reaches into it. A row
-- emitted outside these ranges renders tinted but unstyled.
local function push_drawn_ranges(ranges, hunk, name, first_row, minus_only)
  if minus_only and name == 'old' then
    for _, change in ipairs(hunk.changes) do
      if change.old_end > change.old_start then
        ranges[#ranges + 1] = { first_row + change.old_start - 1, first_row + change.old_end - 1 }
      end
    end
  elseif #hunk[name].rows > 0 then
    ranges[#ranges + 1] = { first_row, first_row + #hunk[name].rows }
  end
end

-- Compute treesitter spans for both sides of a file, and leave each hunk's side
-- the rows its cells read them from: side.spans, where the side's row 1 sits at
-- index side.span_base. In full mode those are the side's whole file, shared by
-- every hunk -- blob.acquire found the content and the patch to agree, so a row
-- maps onto its parsed line by its number alone. In fragment mode they are the
-- hunk's own rows, parsed alone. `langs_by_side` differs between sides only for
-- renames that change the extension, where the old side is not the new side's
-- language at all.
local function compute_spans(file, langs_by_side, ctx)
  local minus_only = not ctx.split

  -- One parse of `lines` for `hunks`. Extraction needs a language and at least
  -- one row to spend it on.
  local function extract(name, hunks, lines, full)
    local ranges = {}
    for _, hunk in ipairs(hunks) do
      local side = hunk[name]
      side.span_base = full and side.start - 1 or 0
      push_drawn_ranges(ranges, hunk, name, side.span_base, minus_only)
    end
    if not langs_by_side[name] or #ranges == 0 then
      return
    end
    local rows, cut_short =
      highlight.line_spans(lines, langs_by_side[name], ranges, ctx.hl_deadline)
    if cut_short then
      ctx.hl_degraded = true
    end
    for _, hunk in ipairs(hunks) do
      hunk[name].spans = rows
    end
  end

  if file.content_mode == 'full' then
    extract('old', file.hunks, file.old_lines, true)
    extract('new', file.hunks, file.new_lines, true)
    return
  end
  for _, hunk in ipairs(file.hunks) do
    extract('old', { hunk }, hunk.old.rows, false)
    extract('new', { hunk }, hunk.new.rows, false)
  end
end

-- Inline layout (codediff.nvim's inline view): deleted blocks render above
-- their inserted blocks, context lines stay undecorated.
local function render_hunk_inline(out, hunk, cell, cols, num_w)
  local function emit(c, old_no, new_no)
    layout.content_line(out, c, old_no, new_no, cols, num_w)
  end

  -- Context rows render from the new side, so their old-side number is not on
  -- the cell and comes from the walker's old pointer instead.
  local old_base = hunk.old.start - 1
  diffparse.walk_hunk(hunk, function(old_row, new_row)
    local c = cell('new', new_row, 'context')
    emit(c, old_base + old_row, c.lnum)
  end, function(change)
    for row = change.old_start, change.old_end - 1 do
      local c = cell('old', row, 'minus')
      emit(c, c.lnum, nil)
    end
    for row = change.new_start, change.new_end - 1 do
      local c = cell('new', row, 'plus')
      emit(c, nil, c.lnum)
    end
  end)
end

-- Side-by-side layout (codediff.nvim's default view): original left,
-- modified right, absent lines shown as filler.
local function render_hunk_split(out, hunk, cell, cols, num_w)
  local function row(left, right)
    layout.split_line(out, left, right, cols, num_w)
  end

  diffparse.walk_hunk(hunk, function(old_row, new_row)
    row(cell('old', old_row, 'context'), cell('new', new_row, 'context'))
  end, function(change)
    local old_n = change.old_end - change.old_start
    local new_n = change.new_end - change.new_start
    for k = 0, math.max(old_n, new_n) - 1 do
      local left = k < old_n and cell('old', change.old_start + k, 'minus') or { filler = true }
      local right = k < new_n and cell('new', change.new_start + k, 'plus') or { filler = true }
      row(left, right)
    end
  end)
end

local function render_hunk(out, hunk, num_w, ctx)
  local function cell(name, row, line_type)
    local side = hunk[name]
    return {
      text = side.rows[row],
      -- Spans, when this side has any (see compute_spans).
      spans = side.spans and side.spans[side.span_base + row - 1],
      line_type = line_type,
      emph = side.emph[row],
      -- Absolute line number of this row on its own side.
      lnum = side.start + row - 1,
      record = side.records and side.records[row],
    }
  end

  local draw = ctx.split and render_hunk_split or render_hunk_inline
  draw(out, hunk, cell, ctx.cols, num_w)

  if hunk.no_newline then
    out:put(layout.note_row('\\ no newline at end of file'))
  end
end

local function render_file(file, ctx)
  local out = buffer.new()
  -- A deleted file has no new side at all, so this falls through to the old
  -- path without needing to know that (see parse_extended_header).
  local patch_path = file.new_path or file.old_path
  local display_path = patch_path or '?'

  -- The OSC 1717 records for this file's rows, nil when the render wasn't asked
  -- for them (or can't carry the path).
  local record = ctx.metadata and patch_path and osc1717.recorder(patch_path)

  -- The notes stand in for the file header git's patch opens with.
  local file_record = record and record('f')
  local function note(text)
    out:put(layout.note_row(text, file_record))
  end
  if file.renamed_from and file.renamed_to then
    note('renamed: ' .. file.renamed_from .. ' => ' .. file.renamed_to)
  end
  if file.old_mode and file.new_mode then
    note('mode changed: ' .. file.old_mode .. ' => ' .. file.new_mode)
  end
  if file.is_binary then
    note('binary: ' .. display_path)
    return out:tostring()
  end
  if #file.hunks == 0 then
    if #out == 0 and (file.is_new or file.is_deleted) then
      note((file.is_new and 'new empty file: ' or 'deleted empty file: ') .. display_path)
    end
    return out:tostring()
  end

  -- Budget: once the global highlighting budget is spent, the remaining files
  -- render with tints only. Oversized sections were already classified plain
  -- by blob.acquire, which owns content_mode.
  local langs_by_side = {}
  if file.content_mode ~= 'plain' and ctx.budget > 0 then
    local full = file.content_mode == 'full'
    langs_by_side.new = langs.lang_for(
      display_path,
      full and (file.is_deleted and file.old_lines or file.new_lines) or nil
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

  local max_lnum = 0
  for _, hunk in ipairs(file.hunks) do
    -- Plain mode (an oversized section) draws the changes without their words.
    if file.content_mode ~= 'plain' then
      engine.emphasize(hunk)
    end
    local last = math.max(hunk.old.start + hunk.old.count, hunk.new.start + hunk.new.count) - 1
    max_lnum = math.max(max_lnum, last)
  end

  if langs_by_side.old or langs_by_side.new then
    ctx.budget = ctx.budget - file.hunk_lines
    compute_spans(file, langs_by_side, ctx)
  end

  local num_w = layout.number_width(max_lnum)
  for i, hunk in ipairs(file.hunks) do
    -- Blank separator so a header reads as belonging to the section below
    -- it, not the one above (the file's first header sticks to its notes;
    -- the file-level separator is added by M.render).
    if i > 1 then
      out:put('\n')
    end
    -- A pure-deletion hunk has a new count of 0 and a new start pointing at the
    -- line *before* it (0 for a whole-file delete), so anchor on the old side.
    local start_lnum = hunk.new.count > 0 and hunk.new.start or hunk.old.start
    -- The record carries git's own @@ +number even so: lazygit numbers a hunk
    -- header by its new side.
    out:put(
      layout.hunk_header(
        display_path,
        start_lnum,
        hunk.heading,
        ctx.cols,
        record and record('h', hunk.new.start)
      )
    )
    if record then
      osc1717.add_hunk_records(hunk, record)
    end
    render_hunk(out, hunk, num_w, ctx)
  end

  return out:tostring()
end

--- Render raw git diff/show output to ANSI, returning the whole document.
--- All-or-nothing by contract: a caller that fails must be able to fall back to
--- the raw diff, and appending it behind a half-written render would show the
--- same hunks twice. opts:
---   cwd    repo directory for blob lookups
---   cols   target width (COLUMNS)
---   layout "side-by-side" for the split view; anything else renders inline
---   metadata  put an OSC 1717 record ahead of each row lazygit can act on
---             (see lib/osc1717.lua)
--- Returns the document and whether it may be cached. It may not be when the
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

  local lines = util.split_lines(ansi.strip_git_colors(input))
  local blocks = diffparse.parse(lines)

  -- Git's output rather than arbitrary text piped through: it has a diff
  -- section, or opens with the commit line of a `git show` that has none. What
  -- is not goes back as it came, colors and all: a log view of lazygit's, when
  -- it is not the kind of graph client.sh sends straight through.
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

  blob.acquire(files, opts.cwd)

  local ctx = {
    cols = opts.cols or 120,
    budget = LIMITS.max_highlighted_lines,
    split = opts.layout == 'side-by-side',
    metadata = opts.metadata,
    hl_deadline = vim.uv.hrtime() + LIMITS.max_highlight_ms * 1e6,
    hl_degraded = false, -- set once the deadline costs any row its spans
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
  return table.concat(out), not ctx.hl_degraded
end

return M
