--- @class chrome.lualine.components.mode
local M = {}

local palette = UI.catppuccin.get_palette()

-- Precompute both per-mode variants: lualine re-evaluates function colors ~30x/sec
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
