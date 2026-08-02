local blob = require("lib.blob")
local diffparse = require("lib.diffparse")
local engine = require("lib.engine")
local highlight = require("lib.highlight")
local langs = require("lib.langs")
local layout = require("lib.layout")
local passthrough = require("lib.passthrough")
local util = require("lib.util")

local M = {}

local LIMITS = {
  max_input_bytes = 2 * 1024 * 1024,
  max_file_section_lines = 20000,
  max_blob_bytes = 1024 * 1024,
  max_highlighted_lines = 8000,
  context_pad_rows = 1,
}

local function hunk_line_total(file)
  local total = 0
  for _, hunk in ipairs(file.hunks) do
    total = total + #hunk.lines
  end
  return total
end

-- Compute treesitter spans for one side. In fragment mode the "file" is the
-- per-hunk reconstruction, so spans are stored on the hunk keyed by side.
local function compute_spans(file, lang)
  if file.content_mode == "full" then
    local sides = {}
    if file.need_old then
      local ranges = highlight.needed_ranges(file.hunks, "old", LIMITS.context_pad_rows)
      sides.old = highlight.line_spans(table.concat(file.old_lines, "\n"), lang, ranges)
    end
    if file.need_new then
      local ranges = highlight.needed_ranges(file.hunks, "new", LIMITS.context_pad_rows)
      sides.new = highlight.line_spans(table.concat(file.new_lines, "\n"), lang, ranges)
    end
    return sides
  end

  for _, hunk in ipairs(file.hunks) do
    hunk.frag_old_spans = highlight.line_spans(table.concat(hunk.frag_old, "\n"), lang, { { 0, math.max(#hunk.frag_old - 1, 0) } })
    hunk.frag_new_spans = highlight.line_spans(table.concat(hunk.frag_new, "\n"), lang, { { 0, math.max(#hunk.frag_new - 1, 0) } })
  end
  return nil
end

-- Treesitter spans for fragment row `row` (1-based) on `side`, or nil when
-- highlighting is off for the file.
local function spans_for(file, hunk, sides, side, row)
  local frag = side == "old" and hunk.frag_old or hunk.frag_new
  local text = frag[row]
  if file.content_mode == "full" then
    local abs = (side == "old" and hunk.old_start or hunk.new_start) + row - 1
    local src_lines = side == "old" and file.old_lines or file.new_lines
    local src_spans = sides and sides[side]
    -- Sanity guard: if the acquired content disagrees with the diff
    -- (reversed diffs, odd hashes), render the diff's own text unstyled.
    if src_lines and src_lines[abs] == text then
      return src_spans and src_spans[abs - 1]
    end
    return nil
  end
  local frag_spans = side == "old" and hunk.frag_old_spans or hunk.frag_new_spans
  return frag_spans and frag_spans[row - 1]
end

-- Inline layout (codediff.nvim's inline view): deleted blocks render above
-- their inserted blocks, context lines stay undecorated.
local function render_hunk_inline(out, hunk, cell, changes, ctx)
  local function emit(side, row, line_type, emph)
    local c = cell(side, row, line_type, emph)
    out[#out + 1] = layout.content_line(c.text, c.spans, c.line_type, c.emph, ctx.cols)
  end

  if changes then
    local mod = 1
    for _, change in ipairs(changes) do
      for row = mod, change.new_start - 1 do
        emit("new", row, "context", nil)
      end
      for row = change.old_start, change.old_end - 1 do
        emit("old", row, "minus", change.old_emph[row])
      end
      for row = change.new_start, change.new_end - 1 do
        emit("new", row, "plus", change.new_emph[row])
      end
      mod = change.new_end
    end
    for row = mod, #hunk.frag_new do
      emit("new", row, "context", nil)
    end
  else
    -- Engine unavailable (plugin missing, timeout, oversized file, CRLF-only
    -- change): keep the patch's own line runs, tints only.
    local old_row, new_row = 0, 0
    for _, hline in ipairs(hunk.lines) do
      if hline.origin == "-" then
        old_row = old_row + 1
        emit("old", old_row, "minus", nil)
      elseif hline.origin == "+" then
        new_row = new_row + 1
        emit("new", new_row, "plus", nil)
      else
        old_row, new_row = old_row + 1, new_row + 1
        emit("new", new_row, "context", nil)
      end
    end
  end
end

-- Side-by-side layout (codediff.nvim's default view): original left,
-- modified right, absent lines shown as filler.
local function render_hunk_split(out, hunk, cell, changes, ctx)
  local function row(left, right)
    out[#out + 1] = layout.split_line(left, right, ctx.cols)
  end

  if changes then
    local old_ptr, new_ptr = 1, 1
    local function context_rows(count)
      for _ = 1, count do
        row(cell("old", old_ptr, "context"), cell("new", new_ptr, "context"))
        old_ptr, new_ptr = old_ptr + 1, new_ptr + 1
      end
    end
    for _, change in ipairs(changes) do
      context_rows(change.new_start - new_ptr)
      old_ptr = change.old_start -- stay aligned if the side gaps ever differ
      local old_n = change.old_end - change.old_start
      local new_n = change.new_end - change.new_start
      for k = 0, math.max(old_n, new_n) - 1 do
        local left = k < old_n
            and cell("old", change.old_start + k, "minus", change.old_emph[change.old_start + k])
          or { filler = true }
        local right = k < new_n
            and cell("new", change.new_start + k, "plus", change.new_emph[change.new_start + k])
          or { filler = true }
        row(left, right)
      end
      old_ptr, new_ptr = change.old_end, change.new_end
    end
    context_rows(#hunk.frag_new - new_ptr + 1)
  else
    -- Patch fallback: pair each minus run with the plus run that follows it.
    local lines = hunk.lines
    local i, old_row, new_row = 1, 0, 0
    while i <= #lines do
      if lines[i].origin == " " then
        old_row, new_row = old_row + 1, new_row + 1
        row(cell("old", old_row, "context"), cell("new", new_row, "context"))
        i = i + 1
      else
        local minus_n, plus_n = 0, 0
        while i <= #lines and lines[i].origin == "-" do
          minus_n, i = minus_n + 1, i + 1
        end
        while i <= #lines and lines[i].origin == "+" do
          plus_n, i = plus_n + 1, i + 1
        end
        for k = 0, math.max(minus_n, plus_n) - 1 do
          local left = k < minus_n and cell("old", old_row + k + 1, "minus") or { filler = true }
          local right = k < plus_n and cell("new", new_row + k + 1, "plus") or { filler = true }
          row(left, right)
        end
        old_row, new_row = old_row + minus_n, new_row + plus_n
      end
    end
  end
end

local function render_hunk(out, file, hunk, sides, lang, ctx)
  local changes = file.content_mode ~= "plain" and engine.compute(hunk.frag_old, hunk.frag_new) or nil
  if changes and #changes == 0 then
    -- The engine sees no difference (e.g. a CRLF-only change: fragments are
    -- CR-stripped); the patch's own runs are the only truthful rendering.
    changes = nil
  end

  local function cell(side, row, line_type, emph)
    local frag = side == "old" and hunk.frag_old or hunk.frag_new
    return {
      text = frag[row] or "",
      spans = lang and spans_for(file, hunk, sides, side, row) or nil,
      line_type = line_type,
      emph = emph,
    }
  end

  if ctx.layout == "side-by-side" then
    render_hunk_split(out, hunk, cell, changes, ctx)
  else
    render_hunk_inline(out, hunk, cell, changes, ctx)
  end

  -- The flag only ever marks the EOF line of a side; the engine may reorder
  -- lines, so a single trailing note keeps it attached to the right hunk.
  for _, hline in ipairs(hunk.lines) do
    if hline.no_newline then
      out[#out + 1] = layout.note_row("\\ no newline at end of file")
      break
    end
  end
end

local function render_file(file, ctx)
  if file.is_combined then
    return passthrough.render_combined(file)
  end

  local out = {}
  local display_path = file.new_path or file.old_path or "?"

  if file.renamed_from and file.renamed_to then
    out[#out + 1] = layout.note_row("renamed: " .. file.renamed_from .. " => " .. file.renamed_to)
  end
  if file.old_mode and file.new_mode and not file.is_new and not file.is_deleted then
    out[#out + 1] = layout.note_row("mode changed: " .. file.old_mode .. " => " .. file.new_mode)
  end
  if file.is_binary then
    out[#out + 1] = layout.note_row("binary: " .. display_path)
    return table.concat(out)
  end
  if #file.hunks == 0 then
    if #out == 0 and (file.is_new or file.is_deleted) then
      out[#out + 1] = layout.note_row((file.is_new and "new empty file: " or "deleted empty file: ") .. display_path)
    end
    return table.concat(out)
  end

  -- Budgets: oversized sections render with tints only, and once the global
  -- highlighting budget is spent the remaining files do too.
  local total_lines = hunk_line_total(file)
  if total_lines > LIMITS.max_file_section_lines then
    file.content_mode = "plain"
  end
  local lang = nil
  if file.content_mode ~= "plain" and ctx.budget > 0 then
    local sample = file.content_mode == "full" and (file.need_new and file.new_lines or file.old_lines) or nil
    lang = langs.lang_for(display_path, sample)
  end

  -- Both the engine and the fallback renderer consume the per-hunk fragments.
  for _, hunk in ipairs(file.hunks) do
    hunk.frag_old = blob.hunk_fragment(hunk, "old")
    hunk.frag_new = blob.hunk_fragment(hunk, "new")
  end

  local sides = nil
  if lang then
    ctx.budget = ctx.budget - total_lines
    sides = compute_spans(file, lang)
  end

  for i, hunk in ipairs(file.hunks) do
    -- Blank separator so a header reads as belonging to the section below
    -- it, not the one above (the file's first header sticks to its notes;
    -- the file-level separator is added by M.render).
    if i > 1 then
      out[#out + 1] = "\n"
    end
    out[#out + 1] = layout.hunk_header(display_path, hunk, ctx.cols)
    render_hunk(out, file, hunk, sides, lang, ctx)
    hunk.frag_old, hunk.frag_new = nil, nil
    hunk.frag_old_spans, hunk.frag_new_spans = nil, nil
  end

  return table.concat(out)
end

--- Render raw git diff/show output to ANSI. opts:
---   cwd    repo directory for blob lookups
---   cols   target width (LAZYGIT_COLUMNS)
---   emit   callback receiving output chunks (called once per block)
---   layout "side-by-side" for the split view; anything else renders inline
---   force_fragment  skip git blob lookups (repo-independent fixtures)
function M.render(input, opts)
  local emit = opts.emit
  if #input > LIMITS.max_input_bytes then
    emit(input)
    return
  end

  input = input:gsub("\27%[[%d;]*m", "")
  local lines = util.split_lines(input)
  local blocks = diffparse.parse(lines)

  local files = {}
  for _, block in ipairs(blocks) do
    if block.kind == "file" then
      files[#files + 1] = block
    end
  end
  local looks_like_git = #files > 0 or (lines[1] and lines[1]:match("^commit %x+"))
  if not looks_like_git then
    emit(input)
    return
  end

  if opts.force_fragment then
    for _, file in ipairs(files) do
      local eligible = not (file.is_combined or file.is_binary) and #file.hunks > 0
      file.content_mode = eligible and "fragment" or "plain"
    end
  else
    blob.acquire(files, opts.cwd, LIMITS)
  end

  local ctx = { cols = opts.cols or 120, budget = LIMITS.max_highlighted_lines, layout = opts.layout }
  local emitted = false
  for _, block in ipairs(blocks) do
    local chunk
    if block.kind == "raw" then
      chunk = passthrough.render_raw(block.lines, ctx.cols)
    else
      chunk = render_file(block, ctx)
    end
    if #chunk > 0 then
      -- Blank separator between sections; raw blocks keep git's own spacing.
      if block.kind == "file" and emitted then
        emit("\n")
      end
      emit(chunk)
      emitted = true
    end
  end
end

return M
