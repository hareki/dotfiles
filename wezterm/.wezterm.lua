local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local config_table = {
	color_scheme = "Catppuccin Mocha",
	enable_tab_bar = false,
	audible_bell = "Disabled",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},

	underline_thickness = "1.6pt",
	underline_position = "200%",

	cursor_blink_ease_in = "Constant",
	cursor_blink_ease_out = "Constant",
	cursor_blink_rate = 600,

	line_height = 1.33,

	font_size = 14.0,
	font = wezterm.font("JetBrainsMono Nerd Font", { weight = "DemiBold" }),
	font_rules = {
		{
			intensity = "Bold",
			italic = false,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font",
				weight = "ExtraBold",
			}),
		},
		{
			intensity = "Bold",
			italic = true,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font",
				weight = "ExtraBold",
				style = "Italic",
			}),
		},
	},

	keys = {
		{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
		{
			key = "C",
			mods = "CTRL",
			action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
		},
	},
}

for k, v in pairs(config_table) do
	config[k] = v
end

return config
