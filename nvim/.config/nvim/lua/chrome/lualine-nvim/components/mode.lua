--- @class chrome.lualine.components.mode
local M = {}

local mode_utils = require('lualine.utils.mode')
local palette = UI.catppuccin.get_palette()

local mode_hl = {}
for _, mode in ipairs({ 'NORMAL', 'O-PENDING' }) do
  mode_hl[mode] = { fg = palette.surface0, bg = palette.blue }
end
for _, mode in ipairs({ 'VISUAL', 'V-LINE', 'V-BLOCK', 'SELECT', 'S-LINE', 'S-BLOCK' }) do
  mode_hl[mode] = { fg = palette.surface0, bg = palette.mauve }
end
for _, mode in ipairs({ 'INSERT', 'SHELL', 'TERMINAL' }) do
  mode_hl[mode] = { fg = palette.surface0, bg = palette.green }
end
for _, mode in ipairs({ 'REPLACE', 'V-REPLACE' }) do
  mode_hl[mode] = { fg = palette.surface0, bg = palette.red }
end
for _, mode in ipairs({ 'COMMAND', 'EX', 'MORE', 'CONFIRM' }) do
  mode_hl[mode] = { fg = palette.surface0, bg = palette.peach }
end

-- lualine re-evaluates function colors on every redraw, so building the
-- inverse table per call would allocate ~30x/sec; both variants are static
-- per mode, precompute them once
local inverse_mode_hl = {}
for mode, c in pairs(mode_hl) do
  inverse_mode_hl[mode] = { fg = c.bg, bg = c.fg, gui = c.gui }
end

--- @param mode string
function M.inverse_mode_hl(mode)
  -- Fallback for raw codes lualine leaves unmapped (e.g. cmdline overstrike 'cr');
  -- without this, an unmapped mode would crash the statusline on every redraw.
  return inverse_mode_hl[mode] or inverse_mode_hl.NORMAL
end

function M.icon_color()
  local mode = mode_utils.get_mode()
  return mode_hl[mode] or mode_hl.NORMAL
end

function M.color()
  local mode = mode_utils.get_mode()
  return M.inverse_mode_hl(mode)
end

return M
