local M = {}

local TAB_WIDTH = 4

--- Split text into lines, with no empty one after a trailing newline and no CR from a CRLF. Here
--- rather than per caller, so patch and blob lines compare byte for byte for full highlighting.
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

-- Printable ASCII, a display cell per byte; not control bytes, which nvim shows as two-cell ^X.
local NON_ASCII = '[^\32-\126]'

--- Index of the first byte outside printable ASCII (NON_ASCII), or nil when there is none.
function M.first_non_ascii(s)
  return s:find(NON_ASCII)
end

-- Everything below a space but the tab, plus DEL: the bytes a terminal acts on rather than shows.
local CONTROL = '[%z\1-\8\10-\31\127]'

--- True when `s` holds a control byte (see CONTROL).
function M.has_control(s)
  return s:find(CONTROL) ~= nil
end

-- Bytes nvim may show as something else: all but printable ASCII and the tab (expand_tabs' job).
local NOT_AS_IS = '[^\t\32-\126]'

--- `s` as nvim shows it, the form display_width measures: control bytes as ^[ or ^L, invalid or
--- unprintable ones as <e9> or <feff>, so content can't restyle, overwrite or shorten its row.
function M.display_form(s)
  if not s:find(NOT_AS_IS) then
    return s
  end
  -- strtrans is nvim's display form, but spells a tab ^I, and a NUL would make the string a Blob.
  return (s:gsub('%z', '^@'):gsub('[^\t]+', vim.fn.strtrans))
end

--- Display width of `s`'s display form. Not strdisplaywidth: in this headless 80-column window a
--- double-width char on the last column counts a third cell.
M.display_width = vim.api.nvim_strwidth

--- Expand tabs to spaces from a 0-based visual column, returning the string and its end column.
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
