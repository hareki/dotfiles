--- @class chrome.lualine-nvim.components.mode
local M = {}

local PALETTE = UI.catppuccin.get_palette()

-- Precompute both per-mode variants: lualine re-evaluates function colors ~30x/sec
local MODE_HL, INVERSE_MODE_HL = {}, {}
for name, color in pairs(UI.mode.colors) do
  MODE_HL[name] = { fg = PALETTE.surface0, bg = PALETTE[color] }
  INVERSE_MODE_HL[name] = { fg = PALETTE[color], bg = PALETTE.surface0 }
end

function M.icon_color()
  return MODE_HL[UI.mode.name()]
end

function M.color()
  return INVERSE_MODE_HL[UI.mode.name()]
end

return M
