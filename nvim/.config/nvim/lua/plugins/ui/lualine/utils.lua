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
    local lualine = require('lualine')
    lualine.refresh({ place = { 'statusline' } })
  end
end

-- Cached function for empty components
local function empty_func()
  return ' '
end

---Create an empty component (1 margin unit)
---@param palette table Color palette
---@param cond function|nil Condition function (synced with main component)
---@return table component Empty lualine component
local function create_empty_comp(palette, cond)
  return {
    empty_func,
    color = { fg = palette.base, bg = palette.base },
    padding = { left = 0, right = 0 },
    separator = { left = '', right = '' },
    cond = cond,
  }
end

---Create margin components (empty_comp repeated n times)
---@param count number Number of margin units
---@param palette table Color palette
---@param cond function|nil Condition function
---@return table[] components Array of empty components
local function create_margins(count, palette, cond)
  local margins = {}
  for _ = 1, count do
    table.insert(margins, create_empty_comp(palette, cond))
  end

  return margins
end

---Default margin/padding values per component type
local DEFAULTS = {
  ['primary-left'] = { margin = { left = 1, right = 0 } },
  ['primary-right'] = { margin = { left = 0, right = 1 } },
  ['secondary-left'] = { padding = { left = 2, right = 0 } },
  ['secondary-right'] = { padding = { left = 0, right = 2 } },
}

---Create lualine components with consistent styling
---@param opts { type: 'primary-left'|'primary-right'|'secondary-left'|'secondary-right', comp: string|function, color: string, icon: string, margin?: {left: number, right: number}, padding?: {left: number, right: number}, [string]: any }
---@return table[] components Array of lualine components (main + margins for primary types)
function M.create_styling_wrapper(opts)
  local ui = require('utils.ui')
  local palette = ui.get_palette()

  local style, _side = opts.type:match('^(%w+)-(%w+)$')
  local is_primary = style == 'primary'
  local defaults = DEFAULTS[opts.type]
  local known_keys =
    { type = true, comp = true, color = true, icon = true, margin = true, padding = true }

  local extra = {}
  for k, v in pairs(opts) do
    if not known_keys[k] then
      extra[k] = v
    end
  end

  local main_comp
  if is_primary then
    main_comp = vim.tbl_extend('force', {
      [1] = opts.comp,
      color = { fg = palette[opts.color], bg = palette.surface0 },
      separator = M.separator,
      icon = { opts.icon .. ' ', color = { fg = palette.base, bg = palette[opts.color] } },
      padding = { left = 0, right = 0 },
    }, extra)
  else
    local text_color = opts.color and palette[opts.color] or palette.subtext0
    local padding = opts.padding or defaults.padding
    main_comp = vim.tbl_extend('force', {
      [1] = opts.comp,
      icon = opts.icon,
      color = { fg = text_color, bg = palette.base },
      padding = padding,
    }, extra)

    return { main_comp }
  end

  local margin = opts.margin or defaults.margin
  local cond = opts.cond
  local left_margins = create_margins(margin.left, palette, cond)
  local right_margins = create_margins(margin.right, palette, cond)

  local result = {}
  vim.list_extend(result, left_margins)
  table.insert(result, main_comp)
  vim.list_extend(result, right_margins)

  return result
end

---Flatten a section containing mixed single components and component arrays
---@param ... table Components or arrays of components
---@return table[] components Flattened array of components
function M.flatten_section(...)
  local result = {}
  for _, item in ipairs({ ... }) do
    if vim.islist(item) and #item > 0 and type(item[1]) == 'table' then
      vim.list_extend(result, item)
    else
      table.insert(result, item)
    end
  end

  return result
end

return M
