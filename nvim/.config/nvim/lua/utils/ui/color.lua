--- @class utils.ui.color
local M = {}

--- @param hex string
--- @return integer r Red component (0-255)
--- @return integer g Green component (0-255)
--- @return integer b Blue component (0-255)
local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

--- @param from string Starting hex color (alpha=0)
--- @param to string Target hex color (alpha=1)
--- @param alpha? number Blend factor (0.0 = fully from, 1.0 = fully to, default: 0.28)
--- @return string hex
function M.blend_hex(from, to, alpha)
  alpha = alpha or 0.28

  local from_r, from_g, from_b = hex_to_rgb(from)
  local to_r, to_g, to_b = hex_to_rgb(to)

  local r = math.floor(from_r * (1 - alpha) + to_r * alpha)
  local g = math.floor(from_g * (1 - alpha) + to_g * alpha)
  local b = math.floor(from_b * (1 - alpha) + to_b * alpha)

  return string.format('#%02x%02x%02x', r, g, b)
end

return M
