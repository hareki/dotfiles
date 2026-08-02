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

--- Unquote a git C-style quoted path ("a\"b", "\303\251" octal escapes, etc).
--- Returns the input unchanged when it is not quoted.
function M.unquote_c_string(s)
  if s:sub(1, 1) ~= '"' or s:sub(-1) ~= '"' then
    return s
  end
  local inner = s:sub(2, -2)
  local out = {}
  local i = 1
  while i <= #inner do
    local c = inner:sub(i, i)
    if c == "\\" then
      local nxt = inner:sub(i + 1, i + 1)
      local oct = inner:match("^([0-7][0-7][0-7])", i + 1)
      if oct then
        out[#out + 1] = string.char(tonumber(oct, 8))
        i = i + 4
      elseif nxt == "n" then
        out[#out + 1] = "\n"
        i = i + 2
      elseif nxt == "t" then
        out[#out + 1] = "\t"
        i = i + 2
      elseif nxt == "r" then
        out[#out + 1] = "\r"
        i = i + 2
      else
        out[#out + 1] = nxt
        i = i + 2
      end
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

--- Display width of a plain string; safe on invalid UTF-8.
--- Printable ASCII is one cell per byte, so the common case never has to cross
--- into vimscript. Control bytes are excluded deliberately: strdisplaywidth
--- measures them as their two-cell ^X form, which the byte count would not match.
function M.display_width(s)
  if not s:find("[^\32-\126]") then
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

function M.is_zero_hash(hex)
  return hex == nil or hex:match("^0+$") ~= nil
end

return M
