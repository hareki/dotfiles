--- @class utils.ui.color
local M = {}

--- Set multiple highlight groups at once
--- @param custom_highlights table<string, vim.api.keyset.highlight> Map of group names to styles
--- @return nil
function M.highlights(custom_highlights)
  for group, style in pairs(custom_highlights) do
    vim.api.nvim_set_hl(0, group, style)
  end
end

--- Convert hex color to RGB components
--- @param hex string Hex color
--- @return integer r Red component (0-255)
--- @return integer g Green component (0-255)
--- @return integer b Blue component (0-255)
function M.hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

--- Blend two hex colors together
--- @param from string Starting hex color (alpha=0)
--- @param to string Target hex color (alpha=1)
--- @param alpha? number Blend factor (0.0 = fully from, 1.0 = fully to, default: 0.28)
--- @return string hex Blended hex color
function M.blend_hex(from, to, alpha)
  alpha = alpha or 0.28

  local from_r, from_g, from_b = M.hex_to_rgb(from)
  local to_r, to_g, to_b = M.hex_to_rgb(to)

  local r = math.floor(from_r * (1 - alpha) + to_r * alpha)
  local g = math.floor(from_g * (1 - alpha) + to_g * alpha)
  local b = math.floor(from_b * (1 - alpha) + to_b * alpha)

  return string.format('#%02x%02x%02x', r, g, b)
end

--- Clear search highlight and restore Snacks word highlights
--- The nvim-hlslens lens handler disables Snacks.words while search highlights are visible
--- (see `nvim-hlslens/utils.lua`'s `search_text_handler`), so a plain :nohlsearch would leave them off.
--- @return nil
function M.nohlsearch()
  vim.cmd.nohlsearch()
  Snacks.words.enable()
  Snacks.words.update()
end

return M
