--- @class chrome.lualine.components.mode
local M = {}

local mode_utils = require('lualine.utils.mode')
local palette = UI.catppuccin.get_palette()

-- lualine re-evaluates function colors on every redraw, so building the
-- inverse table per call would allocate ~30x/sec; both variants are static
-- per mode, precompute them once
local mode_hl, inverse_mode_hl = {}, {}
for color, modes in pairs({
  blue = { 'NORMAL', 'O-PENDING' },
  mauve = { 'VISUAL', 'V-LINE', 'V-BLOCK', 'SELECT', 'S-LINE', 'S-BLOCK' },
  green = { 'INSERT', 'SHELL', 'TERMINAL' },
  red = { 'REPLACE', 'V-REPLACE' },
  peach = { 'COMMAND', 'EX', 'MORE', 'CONFIRM' },
}) do
  for _, mode in ipairs(modes) do
    mode_hl[mode] = { fg = palette.surface0, bg = palette[color] }
    inverse_mode_hl[mode] = { fg = palette[color], bg = palette.surface0 }
  end
end

function M.icon_color()
  local mode = mode_utils.get_mode()
  return mode_hl[mode] or mode_hl.NORMAL
end

function M.color()
  -- Fallback for raw codes lualine leaves unmapped (e.g. cmdline overstrike 'cr');
  -- without this, an unmapped mode would crash the statusline on every redraw.
  return inverse_mode_hl[mode_utils.get_mode()] or inverse_mode_hl.NORMAL
end

return M
