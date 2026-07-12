--- @alias utils.ui.catppuccin.Palette { rosewater: string, flamingo: string, pink: string, mauve: string, red: string, maroon: string, peach: string, yellow: string, green: string, teal: string, sky: string, sapphire: string, blue: string, lavender: string, text: string, subtext1: string, subtext0: string, overlay2: string, overlay1: string, overlay0: string, surface2: string, surface1: string, surface0: string, base: string, mantle: string, crust: string }

--- @class utils.ui.catppuccin.Ext
--- @field surface15 string
--- @field conflict_current string
--- @field conflict_current_label string
--- @field conflict_incoming string
--- @field conflict_incoming_label string
--- @field diff_add_word string
--- @field diff_delete_word string
--- @field snippet_tab_stop string

--- Extension colors that complement the catppuccin palette
local ext = {
  surface15 = '#4f5164', -- Between palette surface1 and surface2
  conflict_current = '#394841',
  conflict_current_label = '#57735b',
  conflict_incoming = '#323c56',
  conflict_incoming_label = '#495d83',
  diff_add_word = '#4e6356',
  diff_delete_word = '#694559',
  snippet_tab_stop = '#414e70',
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

--- @alias utils.ui.catppuccin.Register fun(palette: utils.ui.catppuccin.Palette, sub_palette: utils.ui.catppuccin.Palette, extension: utils.ui.catppuccin.Ext): table<string, vim.api.keyset.highlight>

--- Resolve a register callback into its highlight table
--- @param register utils.ui.catppuccin.Register
--- @return table<string, vim.api.keyset.highlight> highlights
local function resolve(register)
  local palette = get_palette()
  local sub_palette = get_palette('latte')
  local extension = get_palette('ext')

  return register(palette, sub_palette, extension)
end

--- Apply a register's highlights directly, bypassing catppuccin's custom_highlights pipeline
--- @param register utils.ui.catppuccin.Register
local function apply(register)
  for group, hl in pairs(resolve(register)) do
    vim.api.nvim_set_hl(0, group, hl)
  end
end

--- Registers already applied via nvim_set_hl (their plugin loaded)
--- @type utils.ui.catppuccin.Register[]
local lazy_registers = {}

local reapply_autocmd_created = false

--- `:colorscheme` wipes nvim_set_hl groups, while eager registers survive through
--- catppuccin's custom_highlights, so lazily applied ones must be re-applied
local function ensure_reapply_autocmd()
  if reapply_autocmd_created then
    return
  end
  reapply_autocmd_created = true

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('utils.ui.catppuccin.reapply', {}),
    callback = function()
      for _, register in ipairs(lazy_registers) do
        apply(register)
      end
    end,
  })
end

--- Create a catppuccin plugin spec with custom highlights.
--- Without plugin_name, highlights merge eagerly into catppuccin's custom_highlights option;
--- with plugin_name, register evaluation and highlight application are deferred until
--- lazy.nvim loads that plugin.
--- @param register utils.ui.catppuccin.Register Callback to generate highlights
--- @param plugin_name? string lazy.nvim plugin name to defer the registration until it loads
--- @return table spec A lazy.nvim plugin spec for catppuccin
local function catppuccin(register, plugin_name)
  return {
    'catppuccin/nvim',
    opts = function(_, opts)
      if plugin_name then
        local package = require('utils.package')
        package.on_load(plugin_name, function()
          table.insert(lazy_registers, register)
          ensure_reapply_autocmd()
          apply(register)
        end)
        return
      end

      opts.custom_highlights =
        vim.tbl_extend('error', opts.custom_highlights or {}, resolve(register))
    end,
  }
end

--- @class utils.ui.catppuccin
--- @field get_palette fun(name?: "frappe" | "latte" | "macchiato" | "mocha" | "ext"): utils.ui.catppuccin.Palette | utils.ui.catppuccin.Ext
--- @overload fun(register: utils.ui.catppuccin.Register, plugin_name?: string): table

--- @type utils.ui.catppuccin
local M = setmetatable({
  get_palette = get_palette,
}, {
  __call = function(_, register, plugin_name)
    return catppuccin(register, plugin_name)
  end,
})

return M
