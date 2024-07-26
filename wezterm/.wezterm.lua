local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'DemiBold', })
config.line_height = 1.33
config.font_size = 14.0
config.font_rules = {
  {
    intensity = 'Bold',
    italic = false,
    font = wezterm.font(
      {
        family = 'JetBrainsMono Nerd Font',
        weight = 'ExtraBold'
      }
    ),
  },

  {
    intensity = 'Bold',
    italic = true,
    font = wezterm.font(
      {
        family = 'JetBrainsMono Nerd Font',
        weight = 'ExtraBold',
        style = 'Italic',
      }
    ),
  },
}

config.enable_tab_bar = false
config.audible_bell = 'Disabled'

config.keys = {
  { key = 'v', mods = 'CTRL', action = act.PasteFrom('Clipboard') },
  {
    key = 'C',
    mods = 'CTRL',
    action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
  }
}

config.default_prog = { 'Arch' }

return config
