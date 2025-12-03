-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 10
config.color_scheme = 'AdventureTime'
config.font = wezterm.font 'JetBrains Mono'

config.front_end = "WebGpu" -- uses Metal on macOS
config.keys = {
    { key = "k", mods = "CMD|SHIFT", action = act.ScrollToPrompt(-1) },
    { key = "j", mods = "CMD|SHIFT", action = act.ScrollToPrompt(1) },
}

-- Finally, return the configuration to wezterm:
return config
