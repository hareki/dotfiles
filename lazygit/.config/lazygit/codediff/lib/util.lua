local M = {}

--- Split text into renderer lines: a trailing newline does not produce an empty
--- last line, and a CRLF's carriage return is not part of the line's text.
--- Normalizing here rather than in each caller is what keeps the patch text and
--- the blob text comparable -- full-content highlighting rests on a diff row and
--- the file row it names being byte for byte the same.
function M.split_lines(text)
  local lines = {}
  local pos = 1
  while pos <= #text do
    local nl = text:find('\n', pos, true)
    local stop = (nl or #text + 1) - 1
    if stop >= pos and text:byte(stop) == 13 then
      stop = stop - 1
    end
    lines[#lines + 1] = text:sub(pos, stop)
    if not nl then
      break
    end
    pos = nl + 1
  end
  return lines
end

-- Printable ASCII is exactly one display cell per byte, so a byte count is a
-- display width and clipping by cells is clipping by bytes. Control bytes are
-- excluded deliberately: strdisplaywidth measures them as their two-cell ^X
-- form, which the byte count would not match.
local NON_ASCII = '[^\32-\126]'

--- True when every byte is printable ASCII (see NON_ASCII).
function M.is_plain_ascii(s)
  return not s:find(NON_ASCII)
end

--- Byte index of the first non-printable-ASCII byte, or nil when there is none.
--- The same predicate as is_plain_ascii, for callers that need to know where
--- the bulk-addressable prefix ends rather than only whether there is one.
function M.first_non_ascii(s)
  return s:find(NON_ASCII)
end

-- Everything below a space except the tab, plus DEL. A tab is left alone
-- because its width depends on the column it starts at, which is the caller's
-- to resolve (expand_tabs).
local CONTROL = '[%z\1-\8\10-\31\127]'
local CARETS = { ['\127'] = '^?' }
for byte = 0, 31 do
  CARETS[string.char(byte)] = '^' .. string.char(byte + 64)
end

--- True when caret_controls would rewrite `s`. A row is cut into segments
--- before it is shown, and asking once per row keeps the scan out of that loop.
function M.has_control(s)
  return s:find(CONTROL) ~= nil
end

--- Control bytes spelled out in caret notation (^[ for ESC, ^L for a form
--- feed), which is how nvim shows them and the two cells display_width measures
--- them as. Content reaches the view as text, never as instructions: a raw
--- escape would restyle or erase the row it sits in, and a raw CR would
--- overwrite it.
function M.caret_controls(s)
  if not s:find(CONTROL) then
    return s
  end
  return (s:gsub(CONTROL, CARETS))
end

--- Display width of a plain string; safe on invalid UTF-8.
--- Printable ASCII never has to cross into vimscript.
function M.display_width(s)
  if M.is_plain_ascii(s) then
    return #s
  end
  local ok, w = pcall(vim.fn.strdisplaywidth, s)
  if ok then
    return w
  end
  return #s
end

--- Expand tabs to spaces relative to a starting visual column (0-based).
--- Returns the expanded string and the resulting visual column.
function M.expand_tabs(s, tab_width, start_col)
  if not s:find('\t', 1, true) then
    return s, start_col + M.display_width(s)
  end
  local out = {}
  local col = start_col
  local pos = 1
  while true do
    local tab = s:find('\t', pos, true)
    if not tab then
      local rest = s:sub(pos)
      out[#out + 1] = rest
      col = col + M.display_width(rest)
      break
    end
    local chunk = s:sub(pos, tab - 1)
    out[#out + 1] = chunk
    col = col + M.display_width(chunk)
    local pad = tab_width - (col % tab_width)
    out[#out + 1] = string.rep(' ', pad)
    col = col + pad
    pos = tab + 1
  end
  return table.concat(out), col
end

return M
