--- @class utils.ui
local M = {}

--- @alias utils.ui.Palette { rosewater: string, flamingo: string, pink: string, mauve: string, red: string, maroon: string, peach: string, yellow: string, green: string, teal: string, sky: string, sapphire: string, blue: string, lavender: string, text: string, subtext1: string, subtext0: string, overlay2: string, overlay1: string, overlay0: string, surface2: string, surface1: string, surface0: string, base: string, mantle: string, crust: string }

--- Set a single highlight group
--- @param group string The highlight group name
--- @param style vim.api.keyset.highlight The highlight definition
--- @return nil
function M.highlight(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- Set multiple highlight groups at once
--- @param custom_highlights table<string, vim.api.keyset.highlight> Map of group names to styles
--- @return nil
function M.highlights(custom_highlights)
  for group, style in pairs(custom_highlights) do
    M.highlight(group, style)
  end
end

--- Save the current highlight state for a list of groups
--- @param groups string[] List of highlight group names
--- @return table<string, vim.api.keyset.highlight> snapshot Map of group names to their current styles
function M.save_hls(groups)
  local snapshot = {}
  for _, group in ipairs(groups) do
    snapshot[group] = vim.api.nvim_get_hl(0, { name = group, link = false })
  end
  return snapshot
end

--- @class utils.ui.Ext
--- @field blue0 string
--- @field blue1 string
--- @field blue2 string
--- @field green0 string
--- @field green1 string
--- @field surface15 string

--- Extension colors that complement the catppuccin palette
local ext = {
  blue0 = '#323c56', -- Darkest blue
  blue1 = '#414e70', -- Mid blue
  blue2 = '#495d83', -- Brightest blue

  green0 = '#394841', -- Darker green
  green1 = '#57735b', -- Brighter green

  surface15 = '#4f5164', -- Between palette surface1 and surface2
}

--- Get a catppuccin color palette, or the extension colors when name is 'ext'
--- @overload fun(name: 'ext'): utils.ui.Ext
--- @param name? "frappe" | "latte" | "macchiato" | "mocha" Flavor name (default: "mocha")
--- @return utils.ui.Palette colors The color palette table
function M.get_palette(name)
  if name == 'ext' then
    return ext
  end

  local palettes = require('catppuccin.palettes')

  return palettes.get_palette(name or 'mocha')
end

--- Create a catppuccin plugin spec with custom highlights
--- Returns a lazy.nvim spec that registers highlights via catppuccin's custom_highlights option.
--- @param register fun(palette: utils.ui.Palette, sub_palette: utils.ui.Palette, extension: utils.ui.Ext): table<string, vim.api.keyset.highlight> Callback to generate highlights
--- @return table spec A lazy.nvim plugin spec for catppuccin
function M.catppuccin(register)
  return {
    'catppuccin/nvim',
    opts = function(_, opts)
      local palette = M.get_palette()
      local sub_palette = M.get_palette('latte')
      local extension = M.get_palette('ext')

      opts.custom_highlights = vim.tbl_extend(
        'error',
        opts.custom_highlights or {},
        register(palette, sub_palette, extension)
      )
    end,
  }
end

--- Convert hex color to RGB components
--- @param hex string Hex color
--- @return integer r Red component (0-255)
--- @return integer g Green component (0-255)
--- @return integer b Blue component (0-255)
function M.hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

--- Blend two hex colors together
--- @param from string Starting hex color (alpha=0)
--- @param to string Target hex color (alpha=1)
--- @param alpha? number Blend factor (0.0 = fully from, 1.0 = fully to, default: 0.18)
--- @return string hex Blended hex color
function M.blend_hex(from, to, alpha)
  alpha = alpha or 0.28

  local from_r, from_g, from_b = M.hex_to_rgb(from)
  local to_r, to_g, to_b = M.hex_to_rgb(to)

  local r = math.floor(from_r * (1 - alpha) + to_r * alpha)
  local g = math.floor(from_g * (1 - alpha) + to_g * alpha)
  local b = math.floor(from_b * (1 - alpha) + to_b * alpha)

  return string.format('#%02x%02x%02x', r, g, b)
end

--- Get fg and bg hex colors from a highlight group
--- @param name string Highlight group name
--- @return { fg: string?, bg: string? } colors Table with fg/bg hex strings
function M.hl_colors(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  return {
    fg = hl.fg and string.format('#%06x', hl.fg) or nil,
    bg = hl.bg and string.format('#%06x', hl.bg) or nil,
  }
end

--- Build pill-shaped virtual text chunks
--- @param content string The text content inside the pill
--- @param inner_hl string Highlight group for the pill content
--- @param outer_hl string Highlight group for the pill caps
--- @return table[] chunks Virtual text chunks: space, left cap, content, right cap
function M.pill_virt_text(content, inner_hl, outer_hl)
  return {
    { ' ' },
    { Conf.Icons.misc.pill_left, outer_hl },
    { content, inner_hl },
    { Conf.Icons.misc.pill_right, outer_hl },
  }
end

--- Calculate the total display width of a pill (space + caps + content)
--- @param content string The text content inside the pill
--- @return integer width Total display width in columns
function M.pill_display_width(content)
  return 1
    + vim.fn.strdisplaywidth(Conf.Icons.misc.pill_left)
    + vim.fn.strdisplaywidth(content)
    + vim.fn.strdisplaywidth(Conf.Icons.misc.pill_right)
end

--- Generate telescope layout configuration for a given size preset
--- @param size 'sm' | 'md' | 'lg' | 'vertical_lg' | 'full' Size preset name
--- @return table layout Layout config with size hint, height, and width functions
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

--- Get the current screen dimensions in columns and rows
--- @return integer screen_w Screen width in columns
--- @return integer screen_h Screen height in rows
function M.screen_size()
  local screen_w = vim.o.columns
  local screen_h = vim.o.lines

  return screen_w, screen_h
end

local computed_input_size = {
  height = 1,
  width = 60,
}

--- Compute actual dimensions from a size configuration
--- @param size config.size.Dimensions | 'input' Size config or 'input' preset
--- @param with_border? boolean Whether to add 2 for border (default false)
--- @return integer width Width in columns
--- @return integer height Height in rows
function M.compute_size(size, with_border)
  local width_in_cols, height_in_rows

  if size == 'input' then
    width_in_cols = computed_input_size.width
    height_in_rows = computed_input_size.height
  else
    local screen_w, screen_h = M.screen_size()

    width_in_cols = math.floor(screen_w * size.WIDTH)
    height_in_rows = math.floor(screen_h * size.HEIGHT)
  end

  return width_in_cols + (with_border and 2 or 0), height_in_rows + (with_border and 2 or 0)
end

--- Compute width/height for a side panel or side preview size preset
--- @param category 'side_panel' | 'side_preview' Size category in config.size
--- @param variant 'sm' | 'md' | 'lg' Variant key within the category
--- @param with_border? boolean Whether to add 2 for border (default false)
--- @return integer width Width in columns
--- @return integer height Height in rows
function M.side_size(category, variant, with_border)
  return M.compute_size(Conf.Size[category][variant], with_border)
end

--- @class utils.ui.WinConfig
--- @field width    integer
--- @field height   integer
--- @field col      integer
--- @field row      integer

--- Generate popup window configuration for a given size preset
--- Calculates centered position and dimensions based on screen size.
--- @param size 'lg' | 'md' | 'sm' | 'input' | 'full' | 'vertical_lg' Size preset name
--- @param with_border boolean | nil Whether to add 2 for border (default false)
--- @return utils.ui.WinConfig config Window config with width, height, col, row
function M.popup_config(size, with_border)
  local screen_w, screen_h = M.screen_size()
  local window_w, window_h

  if size == 'input' then
    window_w = computed_input_size.width
    window_h = computed_input_size.height
  else
    local dimensions = Conf.Size.popup[size]
    if dimensions.WIDTH <= 1 then
      window_w = math.floor(screen_w * dimensions.WIDTH)
    else
      window_w = dimensions.WIDTH
    end

    if dimensions.HEIGHT <= 1 then
      window_h = math.floor(screen_h * dimensions.HEIGHT)
    else
      window_h = dimensions.HEIGHT
    end

    if dimensions.WIDTH_OFFSET then
      window_w = math.max(window_w + dimensions.WIDTH_OFFSET, 1)
    end

    if dimensions.HEIGHT_OFFSET then
      window_h = math.max(window_h + dimensions.HEIGHT_OFFSET, 1)
    end

    if dimensions.MIN_WIDTH and window_w < dimensions.MIN_WIDTH then
      window_w = dimensions.MIN_WIDTH
    end

    if dimensions.MIN_HEIGHT and window_h < dimensions.MIN_HEIGHT then
      window_h = dimensions.MIN_HEIGHT
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

--- Create a which-key.nvim plugin spec with group specs and/or icon rules
--- Returns a lazy.nvim spec that contributes to which-key's configuration.
--- Icon rules are prepended (higher priority than generic rules in the main spec).
--- @module 'which-key'
--- @param config { specs?: wk.Spec, rules?: wk.IconRule | wk.IconRule[] }
--- @return table spec A lazy.nvim plugin spec for which-key.nvim
function M.which_key(config)
  local specs = config.specs
  local rules = config.rules

  -- Normalize: single spec { '<leader>a', group = '...' } → list of specs
  if specs and type(specs[1]) == 'string' then
    specs = { specs }
  end

  -- Normalize: single rule { pattern = '...' } → list of rules
  if rules and (rules.pattern or rules.plugin) then
    rules = { rules }
  end

  return {
    'hareki/which-key.nvim',
    opts = function(_, opts)
      if specs then
        opts.spec = opts.spec or {}
        vim.list_extend(opts.spec, specs)
      end

      if rules then
        opts.icons = opts.icons or {}
        opts.icons.rules = opts.icons.rules or {}
        -- Prepend: plugin-specific rules have higher priority than generic ones
        for i, rule in ipairs(rules) do
          table.insert(opts.icons.rules, i, rule)
        end
      end
    end,
  }
end

return M
