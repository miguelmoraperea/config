local wezterm = require("wezterm")

local launch_menu = {
	{
		args = { "btop" },
	},
	{
		label = "Scratchpad",
		args = { "nvim", "/home/mrnugget/tmp/scratchpad.md" },
		set_environment_variables = { KITTY_COLORS = "dark" },
	},
}

-- Colors migrated from Alacritty config
local colors = {
	foreground = "#cdcecf",
	background = "#192330",

	cursor_bg = "#cdcecf",
	cursor_fg = "#192330",
	cursor_border = "#cdcecf",

	selection_fg = "#cdcecf",
	selection_bg = "#393b44",

	scrollbar_thumb = "#393b44",

	-- The color of the split lines between panes
	split = "#575860",

	ansi = {
		"#393b44", -- black
		"#c94f6d", -- red
		"#81b29a", -- green
		"#dbc074", -- yellow
		"#719cd6", -- blue
		"#9d79d6", -- magenta
		"#63cdcf", -- cyan
		"#dfdfe0", -- white
	},
	brights = {
		"#575860", -- bright black
		"#d16983", -- bright red
		"#8ebaa4", -- bright green
		"#e0c989", -- bright yellow
		"#86abdc", -- bright blue
		"#baa1e2", -- bright magenta
		"#7ad5d6", -- bright cyan
		"#e4e4e5", -- bright white
	},
	indexed = {
		[16] = "#f4a261",
		[17] = "#d67ad2",
	},
}

local is_macos = wezterm.target_triple:match("darwin") ~= nil

return {
	enable_tab_bar = false,

	-- Font configuration from Alacritty
	font = wezterm.font({
		family = "JetBrainsMono Nerd Font Mono",
		weight = "ExtraLight",
	}),
	font_size = 16.0,

	-- Font rules for bold, italic, and bold italic
	font_rules = {
		{
			intensity = "Bold",
			italic = false,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font Mono",
				weight = "ExtraLight",
			}),
		},
		{
			intensity = "Normal",
			italic = true,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font Mono",
				style = "Italic",
			}),
		},
		{
			intensity = "Bold",
			italic = true,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font Mono",
				weight = "Light",
				style = "Italic",
			}),
		},
	},

	-- Cell width adjustment (similar to Alacritty's font offset x=-2)
	cell_width = 0.9,

	-- Line height adjustment (similar to Alacritty's font offset y=4)
	line_height = 1.1,

	-- Window padding
	window_padding = {
		left = "1cell",
		right = "1cell",
		top = "0.5cell",
		bottom = "0.5cell",
	},

	colors = colors,

	launch_menu = launch_menu,

	keys = {
		{
			key = "f",
			mods = "SHIFT|SUPER",
			action = wezterm.action.ToggleFullScreen,
		},
		{
			key = "Enter",
			mods = "SHIFT",
			action = wezterm.action({ SendString = "\x1b\r" }),
		},
	},
}
