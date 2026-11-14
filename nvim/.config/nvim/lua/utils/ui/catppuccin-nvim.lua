--- @alias utils.ui.catppuccin-nvim.PaletteKey 'rosewater' | 'flamingo' | 'pink' | 'mauve' | 'red' | 'maroon' | 'peach' | 'yellow' | 'green' | 'teal' | 'sky' | 'sapphire' | 'blue' | 'lavender' | 'text' | 'subtext1' | 'subtext0' | 'overlay2' | 'overlay1' | 'overlay0' | 'surface2' | 'surface1' | 'surface0' | 'base' | 'mantle' | 'crust'

--- @alias utils.ui.catppuccin-nvim.Palette table<utils.ui.catppuccin-nvim.PaletteKey, string>

--- @class utils.ui.catppuccin-nvim.Ext
--- @field surface15 string
--- @field conflict_current string
--- @field conflict_current_label string
--- @field conflict_incoming string
--- @field conflict_incoming_label string
--- @field snippet_tab_stop string
--- @field diff_add_word string
--- @field diff_delete_word string

--- Extension colors that complement the catppuccin palette
local EXT = {
  surface15 = '#4f5164', -- Between palette surface1 and surface2
  conflict_current = '#394841',
  conflict_current_label = '#57735b',
  conflict_incoming = '#323c56',
  conflict_incoming_label = '#495d83',
  snippet_tab_stop = '#414e70',

  diff_add_word = '#4b5c5d',
  diff_delete_word = '#5f465f',
}

--- Get a catppuccin color palette, or the extension colors when name is 'ext'
--- @overload fun(name: 'ext'): utils.ui.catppuccin-nvim.Ext
--- @param name? "frappe" | "latte" | "macchiato" | "mocha" Flavor name (default: "mocha")
--- @return utils.ui.catppuccin-nvim.Palette colors
local function get_palette(name)
  if name == 'ext' then
    return EXT
  end

  local palettes = require('catppuccin.palettes')

  return palettes.get_palette(name or 'mocha')
end

--- @alias utils.ui.catppuccin-nvim.Register fun(palette: utils.ui.catppuccin-nvim.Palette, extension: utils.ui.catppuccin-nvim.Ext): table<string, vim.api.keyset.highlight>

--- Resolve a register callback into its highlight table
--- @param register utils.ui.catppuccin-nvim.Register
--- @return table<string, vim.api.keyset.highlight> highlights
local function resolve(register)
  return register(get_palette(), get_palette('ext'))
end

--- A catppuccin spec fragment merging the highlights into custom_highlights, or, with
--- plugin_name, applying them when lazy.nvim loads it (right before its setup() and after)
--- @param register utils.ui.catppuccin-nvim.Register
--- @param plugin_name? string lazy.nvim plugin name to defer the registration until it loads
--- @return table spec A lazy.nvim spec: the catppuccin fragment, plus one on plugin_name if given
local function catppuccin(register, plugin_name)
  if not plugin_name then
    return {
      'catppuccin/nvim',
      opts = function(_, opts)
        opts.custom_highlights = vim.tbl_extend('error', opts.custom_highlights, resolve(register))
      end,
    }
  end

  local function apply()
    -- `:colorscheme` wipes nvim_set_hl groups, while eager registers survive through
    -- catppuccin's custom_highlights; Snacks re-applies the groups it sets on ColorScheme
    local snacks_util = require('snacks.util')
    snacks_util.set_hl(resolve(register))
  end

  return {
    {
      'catppuccin/nvim',
      opts = function()
        vim.api.nvim_create_autocmd('User', {
          pattern = 'LazyLoad',
          callback = function(event)
            if event.data == plugin_name then
              apply()
              return true
            end
          end,
        })
      end,
    },
    -- LazyLoad runs scheduled, after the loading keypress draws, so also apply as opts resolve,
    -- just before setup(); the plugin needs its own opts or config, or lazy starts calling setup()
    {
      plugin_name,
      optional = true,
      opts = apply,
    },
  }
end

--- @class utils.ui.catppuccin-nvim
--- @field get_palette fun(name?: "frappe" | "latte" | "macchiato" | "mocha" | "ext"): utils.ui.catppuccin-nvim.Palette | utils.ui.catppuccin-nvim.Ext
--- @overload fun(register: utils.ui.catppuccin-nvim.Register, plugin_name?: string): table

--- @type utils.ui.catppuccin-nvim
local M = setmetatable({
  get_palette = get_palette,
}, {
  __call = function(_, register, plugin_name)
    return catppuccin(register, plugin_name)
  end,
})

return M
