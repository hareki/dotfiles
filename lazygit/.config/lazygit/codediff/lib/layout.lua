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

  -- Printable ASCII is one cluster of one cell per byte, and a composing mark
  -- can only attach to the byte immediately before the first non-ASCII one, so
  -- everything ahead of that byte is taken (or cut) in bulk. Every row of a
  -- side-by-side diff is clipped to its cell, and a source line whose one
  -- non-ASCII byte sits past the cell edge is then answered without walking a
  -- single cluster.
  local bulk = math.max(s:find("[^\32-\126]") - 2, 0)
  if bulk >= limit then
    local clipped = s:sub(1, math.max(limit, 0))
    return clipped, #clipped
  end

  local ok, count = pcall(vim.fn.strchars, s, 1)
  if not ok then
    local clipped = s:sub(1, limit)
    return clipped, util.display_width(clipped)
  end
  -- Cluster by cluster from there, on the same terms as clusters() above (see
  -- its note on skipcc and composing marks), but only as far as the limit: what
  -- gets clipped away never has to be measured.
  local out = { s:sub(1, bulk) }
  w = bulk
  for i = bulk, count - 1 do
    local text = vim.fn.strcharpart(s, i, 1, 1)
    local cw = util.display_width(text)
    if w + cw > limit then
      break
    end
    out[#out + 1] = text
    w = w + cw
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

-- ansi.style costs two string.format calls and a concat, and a render emits one
-- style per segment of every row over a tiny set of distinct styles: each
-- capture the theme defines, times the five diff backgrounds. theme.attrs hands
-- back one stable table per capture, so its identity keys the memo directly and
-- the hot path never builds a key string.
--
-- Bounded by the colorscheme rather than by anything a diff can contain, which
-- matters because the daemon serves requests for up to an hour. Weak keys so an
-- attrs table theme.attrs ever stopped handing out takes its styles with it.
local NO_ATTRS = {}
local styles = setmetatable({}, { __mode = "k" })

local function segment_sgr(attrs, bg)
  local key = attrs or NO_ATTRS
  local by_bg = styles[key]
  if not by_bg then
    by_bg = {}
    styles[key] = by_bg
  end
  local bg_key = bg or false
  local sgr = by_bg[bg_key]
  if not sgr then
    sgr = ansi.style({
      fg = attrs and attrs.fg or palette.default_fg,
      bg = bg,
      bold = attrs and attrs.bold or false,
      italic = attrs and attrs.italic or false,
      underline = attrs and attrs.underline or false,
    })
    by_bg[bg_key] = sgr
  end
  return sgr
end

-- Same memo for the runs that carry a background but no syntax: row padding,
-- the side-by-side separator and the filler cells (whose whole rendered run is
-- fixed by its width).
local fills = {}
local bar = nil

local function fill_sgr(bg)
  local key = bg or false
  local sgr = fills[key]
  if not sgr then
    sgr = ansi.style({ bg = bg })
    fills[key] = sgr
  end
  return sgr
end

-- A filler run is as long as the cell, so unlike the style memos this one is
-- keyed by something the daemon can keep being handed new values of (the view
-- width, once per terminal resize). Two entries are live at a time; the cap
-- keeps a daemon that has seen a hundred resizes from holding a run for each.
local FILLER_CACHE_MAX = 8
local fillers, n_fillers = {}, 0

local function filler_run(width)
  local run = fillers[width]
  if not run then
    if n_fillers >= FILLER_CACHE_MAX then
      fillers, n_fillers = {}, 0
    end
    run = ansi.styled({ fg = palette.filler_fg }, string.rep(FILLER_CHAR, width))
    fillers[width] = run
    n_fillers = n_fillers + 1
  end
  return run
end

local function by_start(x, y)
  return x.s1 < y.s1
end

-- The sweep below needs the spans in start order. Sorting in place is safe:
-- a row's spans are rendered once, and sorting is idempotent even if that ever
-- stops holding. Query order is close to sorted already, so the scan that
-- decides whether to sort at all usually replaces the sort outright.
local function sort_by_start(spans)
  for i = 2, #spans do
    if spans[i].s1 < spans[i - 1].s1 then
      table.sort(spans, by_start)
      return
    end
  end
end

-- Winner per segment, resolved by a left-to-right sweep over the spans sorted
-- by start. Every span edge is also a segment boundary, so a span that is
-- still open at a segment's start covers the whole segment; the active set is
-- the treesitter nesting depth, never the line's span count (a scan per
-- segment turns a minified line into seconds of CPU).
--
-- The active set is an array compacted in place as spans expire, not a set
-- keyed by span: `pairs` in the innermost loop of the renderer is a loop
-- LuaJIT cannot compile at all.
--
-- Span ends are compared unclamped. A span reaching past the line covers every
-- segment the sweep visits either way, since the last boundary (len + 1) never
-- starts a non-empty segment.
--
-- `stop_col`, when given, is a display column the caller will not render past
-- AND a byte offset of the same row (only an all-ASCII row qualifies): every
-- side-by-side row is clipped to its cell, and the spans beyond the cut would
-- be resolved for text nobody sees.
local function segment_winners(spans, boundaries, nb, stop_col)
  local n_spans = #spans
  local winners = {}
  local active = {}
  local n_active, next_span = 0, 1
  for bi = 1, nb - 1 do
    local a = boundaries[bi]
    if stop_col and a > stop_col then
      break
    end
    while next_span <= n_spans and spans[next_span].s1 <= a do
      n_active = n_active + 1
      active[n_active] = spans[next_span]
      next_span = next_span + 1
    end
    local best
    local kept = 0
    for k = 1, n_active do
      local span = active[k]
      if span.e1 > a then
        kept = kept + 1
        active[kept] = span
        if not best or span.prio > best.prio or (span.prio == best.prio and span.order > best.order) then
          best = span
        end
      end
    end
    n_active = kept
    winners[bi] = best
  end
  return winners
end

-- Emit one content line in codediff.nvim's style: syntax fg over the
-- CodeDiffLine* bg, char-level emphasis as the CodeDiffChar* bg, context lines
-- undecorated. Tabs are expanded against the running visual column, repeated
-- SGR sequences are collapsed, and `limit` (when given) bounds the row to that
-- many display cells.
--
-- Segments are written straight into `out` from index `n` rather than
-- materialized first: a diff is tens of thousands of segments, and the
-- intermediate row table was pure garbage. Returns the new index, the ending
-- display column and the row's background.
--
-- spans: 1-based byte spans from highlight.line_spans (may be nil)
-- emph_ranges: 1-based {s, e-exclusive} byte ranges (may be nil)
local function emit_line(out, n, text, spans, line_type, emph_ranges, limit)
  local p = palette
  local line_bg, emph_bg
  if line_type == "minus" then
    line_bg, emph_bg = p.minus_bg, p.minus_emph_bg
  elseif line_type == "plus" then
    line_bg, emph_bg = p.plus_bg, p.plus_emph_bg
  end

  local len = #text
  local boundaries = { 1, len + 1 }
  local nb = 2
  local n_spans = spans and #spans or 0
  if n_spans > 0 then
    sort_by_start(spans)
    for i = 1, n_spans do
      local span = spans[i]
      local s1 = span.s1
      -- A span starting past the line's end contributes nothing: its range
      -- clamps to empty, and the sweep never reaches its start either.
      if s1 <= len then
        local e1 = span.e1
        boundaries[nb + 1] = s1
        boundaries[nb + 2] = e1 <= len + 1 and e1 or len + 1
        nb = nb + 2
      end
    end
  end
  local n_emph = emph_ranges and #emph_ranges or 0
  for i = 1, n_emph do
    local r = emph_ranges[i]
    if r.s <= len then
      boundaries[nb + 1] = r.s
      boundaries[nb + 2] = r.e <= len + 1 and r.e or len + 1
      nb = nb + 2
    end
  end
  table.sort(boundaries)

  -- Printable ASCII is exactly one display cell per byte, so a row built only
  -- from it needs neither tab expansion nor a width measurement per segment.
  -- It also makes a byte offset a display column, which is what lets a clipped
  -- row stop resolving spans at the cut.
  local simple = not text:find("[^\32-\126]")
  local winners = nb > 2 and n_spans > 0 and segment_winners(spans, boundaries, nb, simple and limit) or nil

  local next_emph = 1
  local col = 0
  local prev = nil
  for bi = 1, nb - 1 do
    local a, b = boundaries[bi], boundaries[bi + 1]
    if b > a then
      if limit and col >= limit then
        break
      end
      local span = winners and winners[bi]
      local attrs = span and theme.attrs(span.capture, span.lang) or nil
      local emph = false
      if n_emph > 0 then
        -- Every range edge is also a segment boundary, so a segment is either
        -- wholly inside a range or wholly outside it, and the ranges arrive
        -- sorted by start (engine.side_char_ranges). A single advancing cursor
        -- therefore answers the coverage question, where rescanning every range
        -- per segment made the range count a quadratic term on
        -- heavily-refactored lines.
        while next_emph <= n_emph and emph_ranges[next_emph].e <= a do
          next_emph = next_emph + 1
        end
        local r = emph_ranges[next_emph]
        emph = r ~= nil and r.s <= a and r.e >= b
      end

      local seg = text:sub(a, b - 1)
      local expanded, next_col
      if simple then
        expanded, next_col = seg, col + (b - a)
      else
        expanded, next_col = util.expand_tabs(seg, TAB_WIDTH, col)
      end
      local truncated = false
      if limit and next_col > limit then
        if simple then
          expanded = expanded:sub(1, limit - col)
          next_col = col + #expanded
        else
          local clipped_w
          expanded, clipped_w = clip_to_width(expanded, limit - col)
          next_col = col + clipped_w
        end
        truncated = true
      end

      local sgr = segment_sgr(attrs, emph and emph_bg or line_bg)
      if sgr ~= prev then
        n = n + 1
        out[n] = sgr
        prev = sgr
      end
      n = n + 1
      out[n] = expanded
      col = next_col
      if truncated then
        -- A clipped segment may leave a cell or two unfilled (a wide char that
        -- did not fit); resuming would splice the line's tail onto its head.
        break
      end
    end
  end
  return n, col, line_bg
end

--- Append one inline content row to `out`, padded to the view width when tinted.
function M.content_line(out, text, spans, line_type, emph_ranges, cols)
  local n, col, line_bg = emit_line(out, #out, text, spans, line_type, emph_ranges, nil)
  if line_bg and cols > col then
    out[n + 1] = fill_sgr(line_bg)
    out[n + 2] = string.rep(" ", cols - col)
    n = n + 2
  end
  out[n + 1] = ansi.reset
  out[n + 2] = "\n"
end

-- Append one side-by-side cell of exactly `width` display cells, truncating
-- overlong lines. cell: { text, spans, line_type, emph } or { filler = true }
-- (codediff renders absent lines as ╱ filler). Returns the new `out` index.
local function render_cell(out, n, cell, width)
  if not cell or cell.filler then
    out[n + 1] = filler_run(width)
    return n + 1
  end
  local col, line_bg
  n, col, line_bg = emit_line(out, n, cell.text, cell.spans, cell.line_type, cell.emph, width)
  if col < width then
    out[n + 1] = fill_sgr(line_bg)
    out[n + 2] = string.rep(" ", width - col)
    n = n + 2
  end
  return n
end

--- Append one side-by-side row to `out`: original cell, separator, modified cell.
function M.split_line(out, left, right, cols)
  local left_w = math.max(math.floor((cols - 1) / 2), 1)
  local right_w = math.max(cols - 1 - left_w, 1)
  bar = bar or ansi.styled({ fg = palette.decoration }, "│")

  local n = render_cell(out, #out, left, left_w)
  out[n + 1] = bar
  n = render_cell(out, n + 1, right, right_w)
  out[n + 1] = ansi.reset
  out[n + 2] = "\n"
end

return M
