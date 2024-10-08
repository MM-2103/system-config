-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config = {
	color_scheme = "Kanagawa (Gogh)",
	font = wezterm.font("IosevkaTerm Nerd Font Mono"),
	font_size = 14.0,
	default_cursor_style = "SteadyBar",
	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
	term = "wezterm",
	use_fancy_tab_bar = false,
	window_decorations = "NONE",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
}
-- and finally, return the configuration to wezterm
return config
