local M = {}

local ESC = string.char(27)

-- One truecolor SGR parameter: 38 selects the foreground, 48 the background.
local function truecolor(selector, rgb)
  return string.format(
    '%d;2;%d;%d;%d',
    selector,
    math.floor(rgb / 65536) % 256,
    math.floor(rgb / 256) % 256,
    rgb % 256
  )
end

--- One SGR sequence restating the whole style from a reset, so no state leaks across segments.
--- attrs: { fg = 0xRRGGBB|nil, bg = 0xRRGGBB|nil, bold, italic, underline }
function M.style(attrs)
  local parts = { '0' }
  if attrs.fg then
    parts[#parts + 1] = truecolor(38, attrs.fg)
  end
  if attrs.bg then
    parts[#parts + 1] = truecolor(48, attrs.bg)
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

--- The end of every output row: no style carries over into the next one.
M.eol = ESC .. '[0m\n'

local SGR = ESC .. '%[[%d;]*m'

--- Strip the SGR sequences git colored a diff with, which only ever open a line: an escape
--- anywhere else is file content, and dropping it would fail the comparison against the blob.
function M.strip_git_colors(s)
  if not s:find(ESC, 1, true) then
    return s
  end
  if not (s:find('^' .. SGR) or s:find('\n' .. SGR)) then
    return s
  end
  return (s:gsub(SGR, ''))
end

function M.styled(attrs, text)
  return M.style(attrs) .. text
end

function M.line(attrs, text)
  return M.style(attrs) .. text .. M.eol
end

return M
