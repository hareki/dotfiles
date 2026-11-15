local ansi = require('lib.ansi')
local theme = require('lib.theme')
local util = require('lib.util')

local M = {}

local FILLER_CHAR = '╱' -- codediff's diff.filler_text default

local palette = theme.palette

-- An upvalue, as it runs per rendered row to stay cheaper than measuring the row.
local first_non_ascii = util.first_non_ascii

-- Clip `s` to at most `limit` display cells, returning it and its width. Both clips go by grapheme
-- cluster (%S, skipcc): a combining mark in NFD text (macOS filenames) measures a cell, adds none.
local function clip_to_width(s, limit)
  local w = util.display_width(s)
  if w <= limit then
    return s, w
  end
  local clipped = vim.call('printf', '%.*S', limit, s)
  return clipped, util.display_width(clipped)
end

-- Same, but keeps the tail behind a leading ellipsis: a path's basename says more than its dirs.
local function clip_left_to_width(s, limit)
  local w = util.display_width(s)
  if w <= limit then
    return s, w
  end
  if limit < 2 then
    return '', 0
  end
  if not first_non_ascii(s) then
    return '…' .. s:sub(#s - limit + 2), limit
  end
  -- Backwards from the tail, measuring only what survives the elision.
  local out = {}
  w = 0
  for i = vim.fn.strchars(s, 1) - 1, 0, -1 do
    local text = vim.fn.strcharpart(s, i, 1, 1)
    local cw = util.display_width(text)
    if w + cw > limit - 1 then
      break
    end
    table.insert(out, 1, text)
    w = w + cw
  end
  return '…' .. table.concat(out), w + 1
end

-- Collapse tabs and line breaks to spaces (a tab would throw off a header's arithmetic, and this
-- is metadata, not indented source), and spell out every other byte nvim shows in another form.
local function one_line(s)
  return util.display_form((s:gsub('[\t\r\n]', ' ')))
end

--- Delta-style boxed hunk header: path, start line and section heading between decoration rules.
--- `record` (an OSC 1717 record, may be nil) goes on the row that names the hunk.
function M.hunk_header(path, lnum, section, cols, record)
  local p = palette
  local num = tostring(lnum)
  local path_plain = one_line(path)
  local heading = section and (': ' .. one_line(section)) or ''
  local plain = path_plain .. ':' .. num .. heading
  local width = math.min(util.display_width(plain) + 2, math.max(cols - 1, 1))

  -- All of it fits inside the rule with a pad cell before the bar, or the box breaks: the path
  -- loses its head first, then the heading its tail, and the line number stays.
  local budget = math.max(width - 1, 1)
  local num_w = #num + 1 -- the colon
  local path_text, path_w = clip_left_to_width(path_plain, math.max(budget - num_w, 0))
  -- Under three cells only the heading's ": " would survive, a stray colon: drop the heading.
  local heading_budget = budget - path_w - num_w
  local heading_text, heading_w = '', 0
  if heading_budget >= 3 then
    heading_text, heading_w = clip_to_width(heading, heading_budget)
  end
  local used = path_w + num_w + heading_w

  local rule = ansi.styled({ fg = p.decoration }, string.rep('─', width))
  local header = ansi.styled({ fg = p.default_fg, bold = true }, path_text)
    .. ansi.styled({ fg = p.decoration }, ':')
    .. ansi.styled({ fg = p.hunk_num, bold = true }, num)
    .. ansi.styled({ fg = p.default_fg }, heading_text)

  -- The bar lands in the corners' column, after `width` rule cells: the pad is the rest (no -1).
  local pad = width - used
  return table.concat({
    rule .. '┐' .. ansi.eol,
    record or '',
    header
      .. string.rep(' ', math.max(pad, 1))
      .. ansi.styled({ fg = p.decoration }, '│')
      .. ansi.eol,
    rule .. '┘' .. ansi.eol,
  })
end

--- A one-off note row (rename, mode change, binary, no newline), an OSC 1717 `record` ahead of it.
function M.note_row(text, record)
  return (record or '') .. ansi.line({ fg = palette.decoration, italic = true }, one_line(text))
end

-- ansi.style per segment, memoized on theme.attrs' stable table per capture, then the background
-- (`false` for none): bounded by the colorscheme, not by any diff the hour-long daemon is handed.
local NO_ATTRS = {}
local styles = vim.defaulttable(function(attrs)
  return vim.defaulttable(function(bg)
    return ansi.style(vim.tbl_extend('force', { fg = palette.default_fg }, attrs, { bg = bg }))
  end)
end)

-- Same memo for the run that carries a background but no syntax: row padding.
local fills = vim.defaulttable(function(bg)
  return ansi.style({ bg = bg })
end)

-- Keyed by the view width, which every terminal resize can change: two entries are live at a time,
-- and the cap keeps a daemon from holding a run for each resize it has seen.
local FILLER_CACHE_MAX = 8
local fillers = {}

local function filler_run(width)
  local run = fillers[width]
  if not run then
    if vim.tbl_count(fillers) >= FILLER_CACHE_MAX then
      fillers = {}
    end
    run = ansi.styled({ fg = palette.filler_fg }, string.rep(FILLER_CHAR, width))
    fillers[width] = run
  end
  return run
end

local function by_start(x, y)
  return x.s1 < y.s1
end

-- The sweep below needs start order. Sorting in place is safe (a row renders once), and query order
-- is close to sorted, so the scan deciding whether to sort usually replaces the sort.
local function sort_by_start(spans)
  for i = 2, #spans do
    if spans[i].s1 < spans[i - 1].s1 then
      table.sort(spans, by_start)
      return
    end
  end
end

-- Reused across rows, as both are fully written before they are read; a row past this many
-- boundaries (a minified line) gets its own winners, or the scratch would pin its spans for good.
local SCRATCH_BOUNDARIES = 1024
local scratch_winners, scratch_active = {}, {}

-- Winner per segment, by a sweep in start order; the active set (the nesting depth) is an array
-- compacted in place, since LuaJIT can't compile `pairs` here. An end past the line needs no clamp.
local function segment_winners(spans, boundaries, nb)
  local n_spans = #spans
  local winners, active = nb <= SCRATCH_BOUNDARIES and scratch_winners or {}, scratch_active
  local n_active, next_span = 0, 1
  for bi = 1, nb - 1 do
    local a = boundaries[bi]
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
        if
          not best
          or span.prio > best.prio
          or (span.prio == best.prio and span.order > best.order)
        then
          best = span
        end
      end
    end
    n_active = kept
    winners[bi] = best
  end
  return winners
end

-- A row type's backgrounds and gutter styles; the number and bar carry the row's background so a
-- tinted row reads as one block. Context rows and filler cells share the untinted style.
local row_styles = vim.defaulttable(function(line_type)
  local p = palette
  local num_fg, bg, emph_bg = p.decoration, nil, nil
  if line_type == 'minus' then
    num_fg, bg, emph_bg = p.minus_num, p.minus_bg, p.minus_emph_bg
  elseif line_type == 'plus' then
    num_fg, bg, emph_bg = p.plus_num, p.plus_bg, p.plus_emph_bg
  end
  return {
    bg = bg,
    emph_bg = emph_bg,
    num = ansi.style({ fg = num_fg, bg = bg }),
    bar = ansi.style({ fg = p.decoration, bg = bg }),
  }
end)

-- Emit one content line in codediff.nvim's style (syntax fg over the line bg, emphasis as the char
-- bg) straight into `out`, clipped to `limit` cells; returns the end column and the row's bg.
-- spans: 1-based byte spans from highlight.line_spans (may be nil)
-- emph_ranges: 1-based {s, e-exclusive} byte ranges (may be nil)
local function emit_line(out, text, spans, line_type, emph_ranges, limit)
  local row_style = row_styles[line_type]
  local line_bg, emph_bg = row_style.bg, row_style.emph_bg

  -- Printable ASCII is a cell per byte, so it needs no tab expansion or measuring, and a cut that
  -- lands in it is made here, before the span work: a composing mark only joins the byte before.
  local nonascii = first_non_ascii(text)
  if limit and #text > limit and (not nonascii or nonascii - 2 >= limit) then
    text, nonascii = text:sub(1, limit), nil
  end
  local simple = not nonascii

  local len = #text
  local boundaries = { 1, len + 1 }
  local nb = 2
  if spans then
    sort_by_start(spans)
    for i = 1, #spans do
      local span = spans[i]
      local s1 = span.s1
      -- A span starting past the end adds nothing: it clamps empty and the sweep never reaches it.
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

  -- Only a non-ASCII row can hold a byte nvim shows in another form, so only such a row respells.
  local respell = not simple and util.display_form(text) ~= text
  local winners = spans and segment_winners(spans, boundaries, nb)

  local next_emph = 1
  local col = 0
  local prev = nil
  for bi = 1, nb - 1 do
    local a, b = boundaries[bi], boundaries[bi + 1]
    if b > a then
      local span = winners and winners[bi]
      local attrs = span and theme.attrs(span.capture, span.lang)
      local emph = false
      if n_emph > 0 then
        -- Range edges are segment boundaries and ranges come sorted, so one advancing cursor
        -- decides coverage; rescanning per segment was quadratic on heavily refactored lines.
        while next_emph <= n_emph and emph_ranges[next_emph].e <= a do
          next_emph = next_emph + 1
        end
        local r = emph_ranges[next_emph]
        emph = r ~= nil and r.s <= a
      end

      local seg = text:sub(a, b - 1)
      local expanded, next_col
      if simple then
        expanded, next_col = seg, col + (b - a)
      else
        -- The display form first, so what is measured and clipped is what is shown.
        local shown = respell and util.display_form(seg) or seg
        expanded, next_col = util.expand_tabs(shown, col)
      end
      -- A clipped segment may leave a cell unfilled (a wide char that did not fit), so it must be
      -- the last: resuming would splice the line's tail onto its head.
      local last = limit and next_col >= limit
      if last then
        local clipped_w
        expanded, clipped_w = clip_to_width(expanded, limit - col)
        next_col = col + clipped_w
      end

      local sgr = styles[attrs or NO_ATTRS][emph and emph_bg or line_bg or false]
      if sgr ~= prev then
        out:put(sgr)
        prev = sgr
      end
      out:put(expanded)
      col = next_col
      if last then
        break
      end
    end
  end
  return col, line_bg
end

-- Line-number gutter

-- The gutter's minimum digits per number, sized per file so text doesn't shift between hunks, and
-- floored at three (as nvim's number column) so it holds across most files a session moves between.
local NUM_MIN_DIGITS = 3

--- Gutter digits for a file, given the widest line number it reaches.
function M.number_width(max_lnum)
  return math.max(#tostring(max_lnum), NUM_MIN_DIGITS)
end

-- One format per gutter width, so a row's numbers cost one call; %s blanks an absent number.
local num_fmts = vim.defaulttable(function(num_w)
  return { pair = '%' .. num_w .. 's %' .. num_w .. 's ', single = '%' .. num_w .. 's ' }
end)

-- Returns the cells the gutter took ahead of the text, counted from what was written so a number
-- wider than reserved widens both together. `record` (may be nil) goes ahead and takes no cells.
local function emit_gutter(out, nums, line_type, record)
  if record then
    out:put(record)
  end
  local style = row_styles[line_type or 'context']
  out:put(style.num, nums, style.bar, '│')
  return #nums + 1
end

--- Append one inline row to `out`: the old number for a minus row, the new for a plus, both for
--- context, then the text, padded when tinted. cell: { text, spans, line_type, emph, record }.
function M.content_line(out, cell, old_no, new_no, cols, num_w)
  local line_type = cell.line_type
  local nums = num_fmts[num_w].pair:format(old_no or '', new_no or '')
  local gutter_w = emit_gutter(out, nums, line_type, cell.record)
  local col, line_bg = emit_line(out, cell.text, cell.spans, line_type, cell.emph, nil)
  local text_w = cols - gutter_w
  if line_bg and text_w > col then
    out:put(fills[line_bg], string.rep(' ', text_w - col))
  end
  out:put(ansi.eol)
end

-- Append one side-by-side cell of exactly `width` cells. cell: { text, spans, line_type, emph,
-- lnum, record } or { filler = true }; its record is skipped when it is `in_effect` for the row.
local function render_cell(out, cell, width, num_w, in_effect)
  local line_type = cell.line_type
  local nums = num_fmts[num_w].single:format(cell.lnum or '')
  local record = cell.record ~= in_effect and cell.record
  local gutter_w = emit_gutter(out, nums, line_type, record)
  -- The gutter is never clipped; only a view a dozen cells wide makes a cell overflow.
  width = math.max(width - gutter_w, 1)
  if cell.filler then
    out:put(filler_run(width))
    return
  end
  local col, line_bg = emit_line(out, cell.text, cell.spans, line_type, cell.emph, width)
  if col < width then
    out:put(fills[line_bg or false], string.rep(' ', width - col))
  end
end

--- Append one side-by-side row to `out`: original cell, separator, modified cell.
function M.split_line(out, left, right, cols, num_w)
  local left_w = math.max(math.floor((cols - 1) / 2), 1)
  local right_w = math.max(cols - 1 - left_w, 1)

  render_cell(out, left, left_w, num_w)
  -- The separator is an untinted gutter bar, so it takes that memoized style.
  out:put(row_styles.context.bar, '│')
  render_cell(out, right, right_w, num_w, left.record)
  out:put(ansi.eol)
end

return M
