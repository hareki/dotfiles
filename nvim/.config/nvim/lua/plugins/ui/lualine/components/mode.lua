---@class Lualine.Components.Mode
local M = {}

local ui = require('utils.ui')
local palette = ui.get_palette()

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

---@param mode string
function M.inverse_mode_hl(mode)
  local c = mode_hl[mode]
  return { fg = c.bg, bg = c.fg, gui = c.gui }
end

function M.icon_color()
  local mode_utils = require('lualine.utils.mode')
  local mode = mode_utils.get_mode()
  return mode_hl[mode]
end

function M.color()
  local mode_utils = require('lualine.utils.mode')
  local mode = mode_utils.get_mode()
  return M.inverse_mode_hl(mode)
end

return M
