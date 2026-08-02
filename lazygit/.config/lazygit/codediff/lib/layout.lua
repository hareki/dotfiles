local ansi = require("lib.ansi")
local theme = require("lib.theme")
local util = require("lib.util")

local M = {}

local TAB_WIDTH = 4
local FILLER_CHAR = "╱" -- codediff's diff.filler_text default

local function pal()
  return theme.palette
end

--- Delta-style boxed hunk header: path, new-side start line and the section
--- heading, framed by decoration-colored rules.
function M.hunk_header(path, hunk, cols)
  local p = pal()
  local num = tostring(hunk.new_start)
  local heading = hunk.heading and (": " .. hunk.heading) or ""
  local plain = (path or "") .. ":" .. num .. heading
  local width = math.min(util.display_width(plain) + 2, math.max(cols - 1, 1))

  local rule = ansi.style({ fg = p.decoration }) .. string.rep("─", width)
  local header = ansi.style({ fg = p.default_fg, bold = true }) .. (path or "")
    .. ansi.style({ fg = p.decoration }) .. ":"
    .. ansi.style({ fg = p.hunk_num, bold = true }) .. num
    .. ansi.style({ fg = p.default_fg }) .. heading

  -- The corners sit after `width` rule cells; the bar must land in the same
  -- column, so the pad is exactly the leftover width (no -1).
  local pad = width - util.display_width(plain)
  return table.concat({
    rule .. "┐" .. ansi.reset .. "\n",
    header .. string.rep(" ", math.max(pad, 1)) .. ansi.style({ fg = p.decoration }) .. "│" .. ansi.reset .. "\n",
    rule .. "┘" .. ansi.reset .. "\n",
  })
end

--- One-off informational rows (rename, mode change, binary, no-newline).
function M.note_row(text)
  return ansi.style({ fg = pal().decoration, italic = true }) .. text .. ansi.reset .. "\n"
end

local function winning_span(spans, a, b)
  local best
  for _, span in ipairs(spans) do
    if span.s1 <= a and span.e1 >= b then
      if not best or span.prio > best.prio or (span.prio == best.prio and span.order > best.order) then
        best = span
      end
    end
  end
  return best
end

-- Build the styled segments for one content line in codediff.nvim's style:
-- syntax fg over the CodeDiffLine* bg, char-level emphasis as the
-- CodeDiffChar* bg, context lines undecorated. Tabs are expanded by the
-- emitters (expansion depends on the running visual column).
--
-- spans: 0-based byte spans from highlight.line_spans (may be nil)
-- emph_ranges: 1-based {s, e-exclusive} byte ranges (may be nil)
local function line_segments(text, spans, line_type, emph_ranges)
  local p = pal()
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

  local segs = {}
  for bi = 1, #boundaries - 1 do
    local a, b = boundaries[bi], boundaries[bi + 1]
    if b > a then
      local seg = text:sub(a, b - 1)
      local span = winning_span(clamped, a, b)
      local attrs = span and theme.attrs(span.capture, span.lang) or nil
      local emph = false
      if emph_ranges then
        for _, r in ipairs(emph_ranges) do
          if r.s <= a and r.e >= b then
            emph = true
            break
          end
        end
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

--- Render one inline content line, padded to the view width when tinted.
function M.content_line(text, spans, line_type, emph_ranges, cols)
  local segs, line_bg = line_segments(text, spans, line_type, emph_ranges)
  local out = {}
  local col = 0
  local prev = nil
  for _, seg in ipairs(segs) do
    local expanded
    expanded, col = util.expand_tabs(seg.text, TAB_WIDTH, col)
    local sgr = ansi.style(seg.style)
    if sgr ~= prev then
      out[#out + 1] = sgr
      prev = sgr
    end
    out[#out + 1] = expanded
  end
  if line_bg then
    local pad = cols - col
    if pad > 0 then
      out[#out + 1] = ansi.style({ bg = line_bg }) .. string.rep(" ", pad)
    end
  end
  out[#out + 1] = ansi.reset
  out[#out + 1] = "\n"
  return table.concat(out)
end

-- Clip a string to at most `limit` display cells (UTF-8 aware). Returns the
-- clipped string and its display width.
local function clip_to_width(s, limit)
  local w = util.display_width(s)
  if w <= limit then
    return s, w
  end
  local ok, pos = pcall(vim.str_utf_pos, s)
  if not ok then
    local clipped = s:sub(1, limit)
    return clipped, util.display_width(clipped)
  end
  local out = {}
  w = 0
  for i = 1, #pos do
    local char = s:sub(pos[i], (pos[i + 1] or #s + 1) - 1)
    local cw = util.display_width(char)
    if w + cw > limit then
      break
    end
    out[#out + 1] = char
    w = w + cw
  end
  return table.concat(out), w
end

-- Render one side-by-side cell to exactly `width` display cells, truncating
-- overlong lines. cell: { text, spans, line_type, emph } or { filler = true }
-- (codediff renders absent lines as ╱ filler).
local function render_cell(out, cell, width)
  if not cell or cell.filler then
    out[#out + 1] = ansi.style({ fg = pal().filler_fg }) .. string.rep(FILLER_CHAR, width)
    return
  end
  local segs, line_bg = line_segments(cell.text, cell.spans, cell.line_type, cell.emph)
  local col = 0
  local prev = nil
  for _, seg in ipairs(segs) do
    if col >= width then
      break
    end
    local expanded, next_col = util.expand_tabs(seg.text, TAB_WIDTH, col)
    if next_col > width then
      local clipped_w
      expanded, clipped_w = clip_to_width(expanded, width - col)
      next_col = col + clipped_w
    end
    local sgr = ansi.style(seg.style)
    if sgr ~= prev then
      out[#out + 1] = sgr
      prev = sgr
    end
    out[#out + 1] = expanded
    col = next_col
  end
  if col < width then
    out[#out + 1] = ansi.style({ bg = line_bg }) .. string.rep(" ", width - col)
  end
end

--- One side-by-side row: original cell, separator, modified cell.
function M.split_line(left, right, cols)
  local left_w = math.max(math.floor((cols - 1) / 2), 1)
  local right_w = math.max(cols - 1 - left_w, 1)
  local out = {}
  render_cell(out, left, left_w)
  out[#out + 1] = ansi.style({ fg = pal().decoration }) .. "│"
  render_cell(out, right, right_w)
  out[#out + 1] = ansi.reset
  out[#out + 1] = "\n"
  return table.concat(out)
end

return M
