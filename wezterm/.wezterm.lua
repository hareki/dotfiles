local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local config_table = {
	default_prog = { "archlinux" },
	color_scheme = "Catppuccin Mocha",
	enable_tab_bar = false,
	audible_bell = "Disabled",

	window_padding = {
		left = 5,
		right = 0,
		top = 7,
		bottom = 0,
	},

	underline_thickness = "2px",
	underline_position = "175%",

	cursor_blink_ease_in = "Constant",
	cursor_blink_ease_out = "Constant",
	cursor_blink_rate = 600,

	line_height = 1.3,

	font_size = 14.5,
	-- font = wezterm.font("JetBrainsMono Nerd Font", { weight = "DemiBold" }),
	-- font_rules = {
	-- 	{
	-- 		intensity = "Bold",
	-- 		italic = false,
	-- 		font = wezterm.font({
	-- 			family = "JetBrainsMono Nerd Font",
	-- 			weight = "ExtraBold",
	-- 		}),
	-- 	},
	-- 	{
	-- 		intensity = "Bold",
	-- 		italic = true,
	-- 		font = wezterm.font({
	-- 			family = "JetBrainsMono Nerd Font",
	-- 			weight = "ExtraBold",
	-- 			style = "Italic",
	-- 		}),
	-- 	},
	-- },
	font = wezterm.font("Maple Mono NF", { weight = "Medium" }),

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
