local M = {}

--- Split text into lines. A trailing newline does not produce an empty last line.
function M.split_lines(text)
  local lines = {}
  local pos = 1
  while true do
    local nl = text:find("\n", pos, true)
    if not nl then
      if pos <= #text then
        lines[#lines + 1] = text:sub(pos)
      end
      break
    end
    lines[#lines + 1] = text:sub(pos, nl - 1)
    pos = nl + 1
  end
  return lines
end

--- Strip a trailing carriage return (CRLF input).
function M.strip_cr(line)
  if line:sub(-1) == "\r" then
    return line:sub(1, -2)
  end
  return line
end

--- True when every byte is printable ASCII, i.e. exactly one display cell each,
--- so a byte count is a display width and clipping by cells is clipping by
--- bytes. Control bytes are excluded deliberately: strdisplaywidth measures
--- them as their two-cell ^X form, which the byte count would not match.
function M.is_plain_ascii(s)
  return not s:find("[^\32-\126]")
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
  if not s:find("\t", 1, true) then
    return s, start_col + M.display_width(s)
  end
  local out = {}
  local col = start_col
  local pos = 1
  while true do
    local tab = s:find("\t", pos, true)
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
    out[#out + 1] = string.rep(" ", pad)
    col = col + pad
    pos = tab + 1
  end
  return table.concat(out), col
end

return M
