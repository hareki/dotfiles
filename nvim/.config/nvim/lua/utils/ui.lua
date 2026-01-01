---@class utils.ui
local M = {}

--- @param group string
--- @param style vim.api.keyset.highlight
function M.highlight(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- A table of custom highlight groups and their corresponding styles.
--- @param custom_highlights table<string, vim.api.keyset.highlight>
function M.highlights(custom_highlights)
  for group, style in pairs(custom_highlights) do
    M.highlight(group, style)
  end
end
--- @alias palette { rosewater: string, flamingo: string, pink: string, mauve: string, red: string, maroon: string, peach: string, yellow: string, green: string, teal: string, sky: string, sapphire: string, blue: string, lavender: string, text: string, subtext1: string, subtext0: string, overlay2: string, overlay1: string, overlay0: string, surface2: string, surface1: string, surface0: string, base: string, mantle: string, crust: string }

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
--- @return palette
function M.get_palette(name)
  return require('catppuccin.palettes').get_palette(name or 'mocha')
end

---@param register fun(palette: palette, sub_palette: palette): table<string, vim.api.keyset.highlight>
function M.catppuccin(register)
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

---@param size 'sm' | 'md' | 'lg' | 'vertical_lg' | 'full'
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

---@return integer screen_w
---@return integer screen_h
function M.screen_size()
  local screen_w = vim.o.columns
  local screen_h = vim.o.lines
  return screen_w, screen_h
end

local computed_input_size = {
  height = 1,
  width = 60,
}

---@param size configs.size.dimensions | 'input'
---@param with_border? boolean
function M.computed_size(size, with_border)
  local width_in_cols, height_in_rows

  if size == 'input' then
    width_in_cols = computed_input_size.width
    height_in_rows = computed_input_size.height
  else
    local screen_w, screen_h = M.screen_size()

    width_in_cols = math.floor(screen_w * size.width)
    height_in_rows = math.floor(screen_h * size.height)
  end

  return width_in_cols + (with_border and 2 or 0), height_in_rows + (with_border and 2 or 0)
end

---@class utils.ui.WinConfig
---@field width    integer
---@field height   integer
---@field col      integer
---@field row      integer
---@param size 'lg' | 'md' | 'sm' | 'input' | 'full' | 'vertical_lg'
---@param with_border boolean | nil
---@return utils.ui.WinConfig
function M.popup_config(size, with_border)
  local size_configs = require('configs.size')
  local screen_w, screen_h = M.screen_size()
  local window_w, window_h

  if size == 'input' then
    window_w = computed_input_size.width
    window_h = computed_input_size.height
  else
    local dimensions = size_configs.popup[size]
    if dimensions.width <= 1 then
      window_w = math.floor(screen_w * dimensions.width)
    else
      window_w = dimensions.width
    end

    if dimensions.height <= 1 then
      window_h = math.floor(screen_h * dimensions.height)
    else
      window_h = dimensions.height
    end

    if dimensions.width_offset then
      window_w = math.max(window_w + dimensions.width_offset, 1)
    end

    if dimensions.height_offset then
      window_h = math.max(window_h + dimensions.height_offset, 1)
    end

    if dimensions.min_width and window_w < dimensions.min_width then
      window_w = dimensions.min_width
    end

    if dimensions.min_height and window_h < dimensions.min_height then
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
    row = row - (size == 'full' and 1 or 0), -- Off center by one row for full screen to cover the winbar
  }
end

--- @param groups string[] | string
function M.clear_hls(groups)
  if type(groups) == 'string' then
    groups = { groups }
  end

  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, {})
  end
end

return M
