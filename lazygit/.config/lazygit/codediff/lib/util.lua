local M = {}

local TAB_WIDTH = 4

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
-- excluded deliberately: nvim shows them in their two-cell ^X form, which the
-- byte count would not match.
local NON_ASCII = '[^\32-\126]'

--- Byte index of the first byte that is not printable ASCII (see NON_ASCII), or
--- nil when every byte is.
function M.first_non_ascii(s)
  return s:find(NON_ASCII)
end

-- Everything below a space except the tab, plus DEL: the bytes a terminal acts
-- on rather than shows.
local CONTROL = '[%z\1-\8\10-\31\127]'

--- True when `s` holds a control byte (see CONTROL).
function M.has_control(s)
  return s:find(CONTROL) ~= nil
end

-- The bytes nvim may show as something other than themselves: everything but
-- printable ASCII and the tab, whose width depends on the column it starts at,
-- which is the caller's to resolve (expand_tabs).
local NOT_AS_IS = '[^\t\32-\126]'

--- `s` the way nvim shows it, which is the form display_width measures: control
--- bytes in caret notation (^[ for ESC, ^L for a form feed), and bytes that are
--- not valid UTF-8 or unprintable characters in angle brackets (<e9>, <feff>).
--- Content reaches the view as text, never as instructions: a raw escape would
--- restyle or erase the row it sits in, a raw CR would overwrite it, and a byte
--- the terminal draws narrower than it was measured would leave the row short.
function M.display_form(s)
  if not s:find(NOT_AS_IS) then
    return s
  end
  -- strtrans is nvim's own display form, but it spells a tab ^I, and a NUL
  -- would turn the string into a Blob on its way into vimscript.
  return (s:gsub('%z', '^@'):gsub('[^\t]+', vim.fn.strtrans))
end

--- Display width of a string in its display form. Not strdisplaywidth, which
--- measures it as laid out in the current window: a double-width character that
--- lands on the last column of this headless 80-column one counts a third cell.
M.display_width = vim.api.nvim_strwidth

--- Expand tabs to spaces relative to a starting visual column (0-based).
--- Returns the expanded string and the resulting visual column.
function M.expand_tabs(s, start_col)
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
    local pad = TAB_WIDTH - (col % TAB_WIDTH)
    out[#out + 1] = string.rep(' ', pad)
    col = col + pad
    pos = tab + 1
  end
  return table.concat(out), col
end

return M
