--- @alias utils.ui.mode.Name 'Normal' | 'Visual' | 'Insert' | 'Replace' | 'Command'

--- @class utils.ui.mode
local M = {}

--- Catppuccin palette key per mode, shared by lualine's mode pill and modicator's CursorLineNr
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
local names = {
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

--- Resolve the mode a `mode()` code is colored as
--- @param mode? string The `mode()` code (default: the current mode)
--- @return utils.ui.mode.Name name
function M.name(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  -- Fallback for codes newer than this table; without it, lualine's mode pill would
  -- crash the statusline on every redraw
  return names[mode] or names[mode:sub(1, 1)] or 'Normal'
end

return M
