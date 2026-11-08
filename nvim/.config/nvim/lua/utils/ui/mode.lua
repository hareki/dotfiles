--- @alias utils.ui.mode.Name 'Normal' | 'Visual' | 'Insert' | 'Replace' | 'Command'

--- @class utils.ui.mode
local M = {}

--- Catppuccin palette key per mode, shared by lualine's mode pill and the CursorLineNr link
--- @type table<utils.ui.mode.Name, string>
M.colors = {
  Normal = 'blue',
  Visual = 'mauve',
  Insert = 'green',
  Replace = 'red',
  Command = 'peach',
}

-- `:help mode()` codes, matched in full first, then by their first character
--- @type table<string, utils.ui.mode.Name>
local NAMES = {
  n = 'Normal', -- Also operator-pending (no*), i_CTRL-O (niI) and terminal-normal (nt)
  v = 'Visual',
  V = 'Visual',
  ['\22'] = 'Visual',
  s = 'Visual',
  S = 'Visual',
  ['\19'] = 'Visual',
  i = 'Insert',
  t = 'Insert',
  ['!'] = 'Insert',
  R = 'Replace', -- Also virtual replace (Rv)
  r = 'Replace', -- Hit-enter prompt, which lualine labels REPLACE
  rm = 'Command',
  ['r?'] = 'Command',
  c = 'Command', -- Also Ex mode (cv) and overstrike (cr)
}

--- The highlight group of the current mode, one of those highlights() defines
--- @return string group e.g. 'NormalMode'
function M.group()
  return M.name() .. 'Mode'
end

--- A `<Name>Mode` foreground group per mode, for catppuccin's custom_highlights
--- @param palette utils.ui.catppuccin-nvim.Palette
--- @return table<string, vim.api.keyset.highlight> groups
function M.highlights(palette)
  local groups = {}
  for name, palette_key in pairs(M.colors) do
    groups[name .. 'Mode'] = { fg = palette[palette_key] }
  end
  return groups
end

--- Resolve the mode the current `mode()` code is colored as
--- @return utils.ui.mode.Name name
function M.name()
  local mode = vim.api.nvim_get_mode().mode
  -- Fallback for codes newer than this table, which would crash lualine's mode pill on every redraw
  return NAMES[mode] or NAMES[mode:sub(1, 1)] or 'Normal'
end

return M
