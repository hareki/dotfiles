--- @class chrome.lualine.utils
local M = {}

--- Shared separator for primary-style pill components
M.separator = { left = Conf.icons.misc.PILL_LEFT, right = Conf.icons.misc.PILL_RIGHT }

local function empty_func()
  return ' '
end

--- Create an empty component (1 margin unit)
--- @param cond function | nil Synced with the main component
--- @return table component
local function create_empty_comp(cond)
  return {
    empty_func,
    color = { fg = 'none', bg = 'none' },
    separator = { left = '', right = '' },
    cond = cond,
  }
end

--- Create margin components (empty_comp repeated n times)
--- @param count number
--- @param cond function | nil
--- @return table[] components
local function create_margins(count, cond)
  local margins = {}
  for _ = 1, count do
    table.insert(margins, create_empty_comp(cond))
  end

  return margins
end

local DEFAULTS = {
  ['primary-left'] = { margin = { left = 1, right = 0 } },
  ['primary-right'] = { margin = { left = 0, right = 1 } },
  ['secondary-left'] = { padding = { left = 2, right = 0 } },
  ['secondary-right'] = { padding = { left = 0, right = 2 } },
}

--- Create lualine components with consistent styling
--- @param opts { type: 'primary-left' | 'primary-right' | 'secondary-left' | 'secondary-right', comp: string | function, color: string, icon: string, margin?: {left: number, right: number}, [string]: any }
--- @return table[] components Array of lualine components (main + margins for primary types)
function M.create_styling_wrapper(opts)
  local palette = UI.catppuccin.get_palette()
  local defaults = DEFAULTS[opts.type]

  local extra = vim.tbl_extend('force', {}, opts)
  for _, key in ipairs({ 'type', 'comp', 'color', 'icon', 'margin' }) do
    extra[key] = nil
  end

  if not vim.startswith(opts.type, 'primary') then
    local text_color = opts.color and palette[opts.color] or palette.subtext0
    return {
      vim.tbl_extend('force', {
        [1] = opts.comp,
        icon = opts.icon,
        color = { fg = text_color, bg = 'none' },
        padding = defaults.padding,
      }, extra),
    }
  end

  local margin = opts.margin or defaults.margin
  local result = create_margins(margin.left, opts.cond)
  table.insert(
    result,
    vim.tbl_extend('force', {
      [1] = opts.comp,
      color = { fg = palette[opts.color], bg = palette.surface0 },
      separator = M.separator,
      icon = { opts.icon .. ' ', color = { fg = palette.base, bg = palette[opts.color] } },
    }, extra)
  )

  return vim.list_extend(result, create_margins(margin.right, opts.cond))
end

--- Wrap a component module that exports `get` and optionally `color`, `icon` and `cond`
--- @param component { get: function, color?: string, icon?: string, cond?: function }
--- @param wrapper_type 'primary-left' | 'primary-right' | 'secondary-left' | 'secondary-right'
--- @param extra? table Further create_styling_wrapper options (e.g. margin)
--- @return table[] components
function M.wrap_component(component, wrapper_type, extra)
  return M.create_styling_wrapper(vim.tbl_extend('force', {
    comp = component.get,
    type = wrapper_type,
    color = component.color,
    icon = component.icon,
    cond = component.cond,
  }, extra or {}))
end

--- Flatten a section containing mixed single components and component arrays
--- @param ... table
--- @return table[] components
function M.flatten_section(...)
  local result = {}
  for _, item in ipairs({ ... }) do
    if vim.islist(item) and type(item[1]) == 'table' then
      vim.list_extend(result, item)
    else
      table.insert(result, item)
    end
  end

  return result
end

return M
