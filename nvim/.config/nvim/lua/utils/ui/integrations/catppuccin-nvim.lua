--- @alias utils.ui.catppuccin.Palette { rosewater: string, flamingo: string, pink: string, mauve: string, red: string, maroon: string, peach: string, yellow: string, green: string, teal: string, sky: string, sapphire: string, blue: string, lavender: string, text: string, subtext1: string, subtext0: string, overlay2: string, overlay1: string, overlay0: string, surface2: string, surface1: string, surface0: string, base: string, mantle: string, crust: string }

--- @class utils.ui.catppuccin.Ext
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
--- @overload fun(name: 'ext'): utils.ui.catppuccin.Ext
--- @param name? "frappe" | "latte" | "macchiato" | "mocha" Flavor name (default: "mocha")
--- @return utils.ui.catppuccin.Palette colors The color palette table
local function get_palette(name)
  if name == 'ext' then
    return ext
  end

  local palettes = require('catppuccin.palettes')

  return palettes.get_palette(name or 'mocha')
end

--- Create a catppuccin plugin spec with custom highlights
--- Returns a lazy.nvim spec that registers highlights via catppuccin's custom_highlights option.
--- @param register fun(palette: utils.ui.catppuccin.Palette, sub_palette: utils.ui.catppuccin.Palette, extension: utils.ui.catppuccin.Ext): table<string, vim.api.keyset.highlight> Callback to generate highlights
--- @return table spec A lazy.nvim plugin spec for catppuccin
local function catppuccin(register)
  return {
    'catppuccin/nvim',
    opts = function(_, opts)
      local palette = get_palette()
      local sub_palette = get_palette('latte')
      local extension = get_palette('ext')

      opts.custom_highlights = vim.tbl_extend(
        'error',
        opts.custom_highlights or {},
        register(palette, sub_palette, extension)
      )
    end,
  }
end

--- @class utils.ui.catppuccin
--- @field get_palette fun(name?: "frappe" | "latte" | "macchiato" | "mocha" | "ext"): utils.ui.catppuccin.Palette | utils.ui.catppuccin.Ext
--- @overload fun(register: fun(palette: utils.ui.catppuccin.Palette, sub_palette: utils.ui.catppuccin.Palette, extension: utils.ui.catppuccin.Ext): table<string, vim.api.keyset.highlight>): table

--- @type utils.ui.catppuccin
local M = setmetatable({
  get_palette = get_palette,
}, {
  __call = function(_, register)
    return catppuccin(register)
  end,
})

return M
