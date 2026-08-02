local M = {}

local ESC = string.char(27)

--- Build a single SGR sequence that fully restates the style (leading reset),
--- so gocui's incremental escape parsing can never leak state across segments.
--- attrs: { fg = 0xRRGGBB|nil, bg = 0xRRGGBB|nil, bold, italic, underline }
function M.style(attrs)
  local parts = { "0" }
  if attrs.fg then
    local fg = attrs.fg
    parts[#parts + 1] = string.format("38;2;%d;%d;%d", math.floor(fg / 65536) % 256, math.floor(fg / 256) % 256, fg % 256)
  end
  if attrs.bg then
    local bg = attrs.bg
    parts[#parts + 1] = string.format("48;2;%d;%d;%d", math.floor(bg / 65536) % 256, math.floor(bg / 256) % 256, bg % 256)
  end
  if attrs.bold then
    parts[#parts + 1] = "1"
  end
  if attrs.italic then
    parts[#parts + 1] = "3"
  end
  if attrs.underline then
    parts[#parts + 1] = "4"
  end
  return ESC .. "[" .. table.concat(parts, ";") .. "m"
end

M.reset = ESC .. "[0m"

--- `text` prefixed with its SGR sequence.
function M.styled(attrs, text)
  return M.style(attrs) .. text
end

--- A complete output row: styled text, reset, newline.
function M.line(attrs, text)
  return M.style(attrs) .. text .. M.reset .. "\n"
end

return M
