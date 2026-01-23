---@class plugins.ui.lualine.utils
local M = {}

---Shared separator for primary-style pill components
M.separator = { left = '', right = '' }

---Check if status line is enabled (not disabled by NVIM_NO_STATUS_LINE env var)
---@return boolean enabled True if status line should be shown
function M.have_status_line()
  return vim.env.NVIM_NO_STATUS_LINE == nil
end

---Refresh the lualine statusline if lualine is loaded
---@return nil
function M.refresh_statusline()
  if package.loaded['lualine'] then
    require('lualine').refresh({ place = { 'statusline' } })
  end
end

---Create a lualine styling wrapper for consistency
---@param opts { type: 'primary'|'secondary', comp: string|function, color: string, icon: string, [string]: any }
---@return table component Lualine component table
function M.create_styling_wrapper(opts)
  local palette = require('utils.ui').get_palette()
  local style = opts.type
  local comp = opts.comp
  local color_key = opts.color
  local icon_str = opts.icon

  -- Extract known keys, rest are passed through to lualine
  local known_keys = { type = true, comp = true, color = true, icon = true }
  local extra = {}
  for k, v in pairs(opts) do
    if not known_keys[k] then
      extra[k] = v
    end
  end

  if style == 'primary' then
    return vim.tbl_extend('force', {
      [1] = comp,
      color = { fg = palette[color_key], bg = palette.surface0 },
      separator = M.separator,
      icon = {
        icon_str .. ' ',
        color = { fg = palette.base, bg = palette[color_key] },
      },
      padding = { left = 0, right = 0 },
    }, extra)
  else -- secondary
    local text_color = color_key and palette[color_key] or palette.subtext0
    return vim.tbl_extend('force', {
      [1] = comp,
      icon = icon_str,
      color = { fg = text_color, bg = palette.base },
      padding = { left = 2, right = 0 },
    }, extra)
  end
end

return M
