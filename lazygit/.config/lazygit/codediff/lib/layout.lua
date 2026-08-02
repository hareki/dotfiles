local ansi = require("lib.ansi")
local theme = require("lib.theme")
local util = require("lib.util")

local M = {}

local TAB_WIDTH = 4
local FILLER_CHAR = "╱" -- codediff's diff.filler_text default

local palette = theme.palette

-- True when every byte is printable ASCII, i.e. exactly one display cell each,
-- so clipping by cells is clipping by bytes. Control bytes are excluded: they
-- measure as their two-cell ^X form.
local function is_plain_ascii(s)
  return not s:find("[^\32-\126]")
end

-- Split into grapheme clusters with their display widths.
--
-- Widths are measured per cluster, never per codepoint: a lone combining mark
-- measures one cell but contributes nothing to the character it attaches to, so
-- summing standalone widths overstates decomposed text (macOS stores filenames
-- NFD) and the caller's layout arithmetic breaks apart. strcharpart's skipcc
-- argument yields a base character together with its composing marks.
local function clusters(s)
  local ok, count = pcall(vim.fn.strchars, s, 1)
  if not ok then
    return nil
  end
  local units = {}
  for i = 0, count - 1 do
    local text = vim.fn.strcharpart(s, i, 1, 1)
    units[#units + 1] = { text = text, w = util.display_width(text) }
  end
  return units
end

-- Clip a string to at most `limit` display cells (UTF-8 aware). Returns the
-- clipped string and its display width.
local function clip_to_width(s, limit)
  local w = util.display_width(s)
  if w <= limit then
    return s, w
  end
  if is_plain_ascii(s) then
    local clipped = s:sub(1, math.max(limit, 0))
    return clipped, #clipped
  end
  local units = clusters(s)
  if not units then
    local clipped = s:sub(1, limit)
    return clipped, util.display_width(clipped)
  end
  local out = {}
  w = 0
  for _, unit in ipairs(units) do
    if w + unit.w > limit then
      break
    end
    out[#out + 1] = unit.text
    w = w + unit.w
  end
  return table.concat(out), w
end

-- Same, but keeps the tail and marks the elision with a leading ellipsis --
-- for paths the basename carries far more signal than the leading directories.
local function clip_left_to_width(s, limit)
  local w = util.display_width(s)
  if w <= limit then
    return s, w
  end
  if limit < 2 then
    return "", 0
  end
  if is_plain_ascii(s) then
    return "…" .. s:sub(#s - limit + 2), limit
  end
  local units = clusters(s)
  if not units then
    return clip_to_width(s, limit)
  end
  local out = {}
  w = 0
  for i = #units, 1, -1 do
    local unit = units[i]
    if w + unit.w > limit - 1 then
      break
    end
    table.insert(out, 1, unit.text)
    w = w + unit.w
  end
  return "…" .. table.concat(out), w + 1
end

-- Collapse the bytes that would break a row out of a single line. A tab is
-- measured relative to column 0, so a header's pieces only add up if none of
-- them contains one; git keeps interior tabs in a section heading, and a tab or
-- a newline in a path survives unquoting. Collapsing beats expanding here: this
-- text is metadata, not source that needs its indentation.
local function one_line(s)
  return (s:gsub("[\t\r\n]", " "))
end

--- Delta-style boxed hunk header: path, new-side start line and the section
--- heading, framed by decoration-colored rules.
function M.hunk_header(path, hunk, cols)
  local p = palette
  -- A pure-deletion hunk has new_count == 0 and a new_start pointing at the
  -- line *before* it (0 for a whole-file delete), so anchor on the old side.
  local num = tostring(hunk.new_count > 0 and hunk.new_start or hunk.old_start)
  local path_plain = one_line(path or "")
  local heading = hunk.heading and (": " .. one_line(hunk.heading)) or ""
  local plain = path_plain .. ":" .. num .. heading
  local width = math.min(util.display_width(plain) + 2, math.max(cols - 1, 1))

  -- Everything must fit inside the rule with at least one pad cell before the
  -- bar, or the box breaks apart. The line number is never dropped: the path
  -- loses its head first, then the section heading its tail.
  local budget = math.max(width - 1, 1)
  local num_w = util.display_width(":" .. num)
  local path_text, path_w = clip_left_to_width(path_plain, math.max(budget - num_w, 0))
  -- Under three cells nothing but the heading's own ": " prefix survives, which
  -- just reads as a stray colon; drop the heading entirely instead.
  local heading_budget = math.max(budget - path_w - num_w, 0)
  local heading_text, heading_w = "", 0
  if heading_budget >= 3 then
    heading_text, heading_w = clip_to_width(heading, heading_budget)
  end
  local used = path_w + num_w + heading_w

  local rule = ansi.styled({ fg = p.decoration }, string.rep("─", width))
  local header = ansi.styled({ fg = p.default_fg, bold = true }, path_text)
    .. ansi.styled({ fg = p.decoration }, ":")
    .. ansi.styled({ fg = p.hunk_num, bold = true }, num)
    .. ansi.styled({ fg = p.default_fg }, heading_text)

  -- The corners sit after `width` rule cells; the bar must land in the same
  -- column, so the pad is exactly the leftover width (no -1).
  local pad = width - used
  return table.concat({
    rule .. "┐" .. ansi.reset .. "\n",
    header .. string.rep(" ", math.max(pad, 1)) .. ansi.styled({ fg = p.decoration }, "│") .. ansi.reset .. "\n",
    rule .. "┘" .. ansi.reset .. "\n",
  })
end

--- One-off informational rows (rename, mode change, binary, no-newline).
function M.note_row(text)
  return ansi.line({ fg = palette.decoration, italic = true }, one_line(text))
end

-- Winner per segment, resolved by a left-to-right sweep over the spans sorted
-- by start. Every span edge is also a segment boundary, so a span that is
-- still open at a segment's start covers the whole segment; the active set is
-- the treesitter nesting depth, never the line's span count (a scan per
-- segment turns a minified line into seconds of CPU).
local function segment_winners(spans, boundaries)
  local sorted = vim.list_slice(spans)
  table.sort(sorted, function(x, y)
    return x.s1 < y.s1
  end)

  local winners = {}
  local active = {}
  local next_span = 1
  for bi = 1, #boundaries - 1 do
    local a = boundaries[bi]
    while next_span <= #sorted and sorted[next_span].s1 <= a do
      active[sorted[next_span]] = true
      next_span = next_span + 1
    end
    local best
    for span in pairs(active) do
      if span.e1 <= a then
        active[span] = nil
      elseif not best or span.prio > best.prio or (span.prio == best.prio and span.order > best.order) then
        best = span
      end
    end
    winners[bi] = best
  end
  return winners
end

-- Build the styled segments for one content line in codediff.nvim's style:
-- syntax fg over the CodeDiffLine* bg, char-level emphasis as the
-- CodeDiffChar* bg, context lines undecorated. Tabs are expanded by the
-- emitters (expansion depends on the running visual column).
--
-- spans: 0-based byte spans from highlight.line_spans (may be nil)
-- emph_ranges: 1-based {s, e-exclusive} byte ranges (may be nil)
local function line_segments(text, spans, line_type, emph_ranges)
  local p = palette
  local line_bg, emph_bg
  if line_type == "minus" then
    line_bg, emph_bg = p.minus_bg, p.minus_emph_bg
  elseif line_type == "plus" then
    line_bg, emph_bg = p.plus_bg, p.plus_emph_bg
  end

  local len = #text
  local boundaries = { 1, len + 1 }
  local clamped = {}
  if spans then
    for _, span in ipairs(spans) do
      local s1 = math.max(span.s + 1, 1)
      local e1 = math.min(span.e == math.huge and len + 1 or span.e + 1, len + 1)
      if e1 > s1 then
        clamped[#clamped + 1] = { s1 = s1, e1 = e1, capture = span.capture, lang = span.lang, prio = span.prio, order = span.order }
        boundaries[#boundaries + 1] = s1
        boundaries[#boundaries + 1] = e1
      end
    end
  end
  if emph_ranges then
    for _, r in ipairs(emph_ranges) do
      if r.s <= len then
        boundaries[#boundaries + 1] = r.s
        boundaries[#boundaries + 1] = math.min(r.e, len + 1)
      end
    end
  end
  table.sort(boundaries)
  local winners = segment_winners(clamped, boundaries)

  local segs = {}
  -- Every range edge is also a segment boundary, so a segment is either wholly
  -- inside a range or wholly outside it, and the ranges arrive sorted by start
  -- (engine.side_char_ranges). A single advancing cursor therefore answers the
  -- coverage question, where rescanning every range per segment made the range
  -- count a quadratic term on heavily-refactored lines.
  local next_emph = 1
  for bi = 1, #boundaries - 1 do
    local a, b = boundaries[bi], boundaries[bi + 1]
    if b > a then
      local seg = text:sub(a, b - 1)
      local span = winners[bi]
      local attrs = span and theme.attrs(span.capture, span.lang) or nil
      local emph = false
      if emph_ranges then
        while next_emph <= #emph_ranges and emph_ranges[next_emph].e <= a do
          next_emph = next_emph + 1
        end
        local r = emph_ranges[next_emph]
        emph = r ~= nil and r.s <= a and r.e >= b
      end
      segs[#segs + 1] = {
        text = seg,
        style = {
          fg = attrs and attrs.fg or p.default_fg,
          bg = emph and emph_bg or line_bg,
          bold = attrs and attrs.bold or false,
          italic = attrs and attrs.italic or false,
          underline = attrs and attrs.underline or false,
        },
      }
    end
  end
  return segs, line_bg
end

-- Append styled segments, expanding tabs against the running visual column and
-- collapsing repeated SGR sequences. `limit` bounds the row to that many display
-- cells; without it the row runs to its natural end. Returns the final column.
local function emit_segments(out, segs, limit)
  local col = 0
  local prev = nil
  for _, seg in ipairs(segs) do
    if limit and col >= limit then
      break
    end
    local expanded, next_col = util.expand_tabs(seg.text, TAB_WIDTH, col)
    local truncated = false
    if limit and next_col > limit then
      local clipped_w
      expanded, clipped_w = clip_to_width(expanded, limit - col)
      next_col = col + clipped_w
      truncated = true
    end
    local sgr = ansi.style(seg.style)
    if sgr ~= prev then
      out[#out + 1] = sgr
      prev = sgr
    end
    out[#out + 1] = expanded
    col = next_col
    if truncated then
      -- A clipped segment may leave a cell or two unfilled (a wide char that
      -- did not fit); resuming would splice the line's tail onto its head.
      break
    end
  end
  return col
end

--- Render one inline content line, padded to the view width when tinted.
function M.content_line(text, spans, line_type, emph_ranges, cols)
  local segs, line_bg = line_segments(text, spans, line_type, emph_ranges)
  local out = {}
  local col = emit_segments(out, segs)
  if line_bg and cols > col then
    out[#out + 1] = ansi.styled({ bg = line_bg }, string.rep(" ", cols - col))
  end
  out[#out + 1] = ansi.reset
  out[#out + 1] = "\n"
  return table.concat(out)
end

-- Render one side-by-side cell to exactly `width` display cells, truncating
-- overlong lines. cell: { text, spans, line_type, emph } or { filler = true }
-- (codediff renders absent lines as ╱ filler).
local function render_cell(out, cell, width)
  if not cell or cell.filler then
    out[#out + 1] = ansi.styled({ fg = palette.filler_fg }, string.rep(FILLER_CHAR, width))
    return
  end
  local segs, line_bg = line_segments(cell.text, cell.spans, cell.line_type, cell.emph)
  local col = emit_segments(out, segs, width)
  if col < width then
    out[#out + 1] = ansi.styled({ bg = line_bg }, string.rep(" ", width - col))
  end
end

--- One side-by-side row: original cell, separator, modified cell.
function M.split_line(left, right, cols)
  local left_w = math.max(math.floor((cols - 1) / 2), 1)
  local right_w = math.max(cols - 1 - left_w, 1)
  local out = {}
  render_cell(out, left, left_w)
  out[#out + 1] = ansi.styled({ fg = palette.decoration }, "│")
  render_cell(out, right, right_w)
  out[#out + 1] = ansi.reset
  out[#out + 1] = "\n"
  return table.concat(out)
end

return M
