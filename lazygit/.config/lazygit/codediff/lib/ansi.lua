local M = {}

local ESC = string.char(27)

--- Build a single SGR sequence that fully restates the style (leading reset),
--- so gocui's incremental escape parsing can never leak state across segments.
--- attrs: { fg = 0xRRGGBB|nil, bg = 0xRRGGBB|nil, bold, italic, underline }
function M.style(attrs)
  local parts = { '0' }
  if attrs.fg then
    local fg = attrs.fg
    parts[#parts + 1] = string.format(
      '38;2;%d;%d;%d',
      math.floor(fg / 65536) % 256,
      math.floor(fg / 256) % 256,
      fg % 256
    )
  end
  if attrs.bg then
    local bg = attrs.bg
    parts[#parts + 1] = string.format(
      '48;2;%d;%d;%d',
      math.floor(bg / 65536) % 256,
      math.floor(bg / 256) % 256,
      bg % 256
    )
  end
  if attrs.bold then
    parts[#parts + 1] = '1'
  end
  if attrs.italic then
    parts[#parts + 1] = '3'
  end
  if attrs.underline then
    parts[#parts + 1] = '4'
  end
  return ESC .. '[' .. table.concat(parts, ';') .. 'm'
end

M.reset = ESC .. '[0m'

local SGR = ESC .. '%[[%d;]*m'

--- Strip the SGR sequences of a diff that git colored. Git is asked for
--- uncolored output, so this almost never has anything to do; the find keeps a
--- pattern scan off the whole input for that case.
---
--- An escape in uncolored output is file content, and has to survive: dropping
--- it shows a line the file does not have, and fails the comparison against the
--- blob that full-content highlighting rests on. Position tells the two apart.
--- Git colors a line from its first byte, while content always sits behind an
--- origin column or an indent, so only colored output starts a line with one.
function M.strip_git_colors(s)
  if not s:find(ESC, 1, true) then
    return s
  end
  if not (s:find('^' .. SGR) or s:find('\n' .. SGR)) then
    return s
  end
  return (s:gsub(SGR, ''))
end

--- `text` prefixed with its SGR sequence.
function M.styled(attrs, text)
  return M.style(attrs) .. text
end

--- A complete output row: styled text, reset, newline.
function M.line(attrs, text)
  return M.style(attrs) .. text .. M.reset .. '\n'
end

return M
