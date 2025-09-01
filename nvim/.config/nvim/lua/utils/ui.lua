---@class utils.ui
local M = {}

--- @param group string
--- @param style vim.api.keyset.highlight
M.highlight = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- A table of custom highlight groups and their corresponding styles.
--- @param custom_highlights table<string, vim.api.keyset.highlight>
M.highlights = function(custom_highlights)
  for group, style in pairs(custom_highlights) do
    M.highlight(group, style)
  end
end
--- @alias palette { rosewater: string, flamingo: string, pink: string, mauve: string, red: string, maroon: string, peach: string, yellow: string, green: string, teal: string, sky: string, sapphire: string, blue: string, lavender: string, text: string, subtext1: string, subtext0: string, overlay2: string, overlay1: string, overlay0: string, surface2: string, surface1: string, surface0: string, base: string, mantle: string, crust: string }

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
--- @return palette
M.get_palette = function(name)
  return require('catppuccin.palettes').get_palette(name or 'mocha')
end

---@param register fun(palette: palette, sub_palette: palette): table<string, vim.api.keyset.highlight>
M.catppuccin = function(register)
  return {
    'catppuccin/nvim',
    opts = function(_, opts)
      local palette = M.get_palette()
      local sub_palette = M.get_palette('latte')
      opts.custom_highlights =
        vim.tbl_extend('error', opts.custom_highlights or {}, register(palette, sub_palette))
    end,
  }
end

---@param size 'sm' | 'md' | 'lg'
function M.telescope_layout(size)
  return {
    size = size, -- Hint to calculate the position
    height = function()
      return M.popup_config(size, true).height
    end,
    width = function()
      return M.popup_config(size, true).width
    end,
  }
end

---@return integer, integer
function M.screen_size()
  local screen_w = vim.opt.columns:get()
  local screen_h = vim.opt.lines:get()
  return screen_w, screen_h
end

function M.computed_size(size)
  local screen_w, screen_h = M.screen_size()
  local width_in_cols = math.floor(screen_w * size.width)
  local height_in_rows = math.floor(screen_h * size.height)
  return width_in_cols, height_in_rows
end

---@class WinConfig
---@field width    integer
---@field height   integer
---@field col      integer
---@field row      integer
---@param size 'lg' | 'md' | 'sm' | 'input'
---@param with_border boolean | nil
---@return WinConfig
function M.popup_config(size, with_border)
  local size_configs = require('configs.size')
  local screen_w, screen_h = M.screen_size()
  local window_w, window_h

  if size == 'input' then
    window_w = 60
    window_h = 1
  else
    local dimensions = size_configs.popup[size]
    window_w = math.floor(screen_w * dimensions.width)
    window_h = math.floor(screen_h * dimensions.height)

    if window_w < dimensions.min_width then
      window_w = dimensions.min_width
    end

    if window_h < dimensions.min_height then
      window_h = dimensions.min_height
    end
  end

  -- Minus 1 to account for the border
  local col = math.floor((screen_w - window_w) / 2) - 1
  local row = math.floor((screen_h - window_h) / 2) - 1

  return {
    -- Some plugins like telescope takes the border into account for the size when rendering the popup
    -- In that case, we should add 2 to the width and height to maintain the same size with the others that do not
    width = window_w + (with_border and 2 or 0),
    height = window_h + (with_border and 2 or 0),
    col = col,
    row = row,
  }
end

return M
