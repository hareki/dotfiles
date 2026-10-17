--- @class chrome.lualine.components.mode
local M = {}

local palette = UI.catppuccin.get_palette()

-- lualine re-evaluates function colors on every redraw, so building the
-- inverse table per call would allocate ~30x/sec; both variants are static
-- per mode, precompute them once
local mode_hl, inverse_mode_hl = {}, {}
for name, color in pairs(UI.mode.colors) do
  mode_hl[name] = { fg = palette.surface0, bg = palette[color] }
  inverse_mode_hl[name] = { fg = palette[color], bg = palette.surface0 }
end

function M.icon_color()
  return mode_hl[UI.mode.name()]
end

function M.color()
  return inverse_mode_hl[UI.mode.name()]
end

return M
