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

--- Whether search matches are currently highlighted
--- @return boolean
function M.search_highlighted()
  -- v:hlsearch alone reads 1 before any search when no shada was loaded
  return vim.v.hlsearch == 1 and vim.fn.getreg('/') ~= ''
end

--- Clear search highlight and bring Snacks word highlights back right away
--- Snacks.words hides references while search matches are highlighted (see its `filter`
--- in `core/snacks-nvim/init.lua`) and would otherwise wait for the next cursor move.
--- @return nil
function M.nohlsearch()
  -- With no search highlighted nothing was hidden, and update() would only clear
  -- and re-request reference highlights that are already current
  local was_highlighted = M.search_highlighted()
  vim.cmd.nohlsearch()
  if was_highlighted then
    Snacks.words.update()
  end
end

return M
