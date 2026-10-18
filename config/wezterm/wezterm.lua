local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Explicitly use Fish as the login shell for new WezTerm panes/tabs.
config.default_prog = { 'fish', '-l' }

-- Mirror the kitty trial so the terminal itself is the main variable.
config.font = wezterm.font("Lilex Nerd Font Mono")
config.font_size = 16
config.color_scheme = "Ayu Mirage"
config.scrollback_lines = 10000

-- Keep the tab bar visible: tabs are the tmux-window-like layer, panes are splits.
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

local smart_splits = wezterm.plugin.require("https://github.com/smart-splits-nvim/backend-wezterm")

smart_splits.apply_to_config(config, {
	-- the default config is shown here; omit the table entirely to use it as-is

	-- directional keys, in order of: left, down, up, right
	direction_keys = { "h", "j", "k", "l" },
	-- move/resize can also be configured separately, e.g.:
	--   direction_keys = {
	--     move = { 'h', 'j', 'k', 'l' },
	--     resize = { 'LeftArrow', 'DownArrow', 'UpArrow', 'RightArrow' },
	--   },

	modifiers = {
		move = "CTRL", -- e.g. CTRL+h to move left
		resize = "META", -- e.g. META+h to resize left
	},

	-- what happens when there's no WezTerm pane in that direction: both a *direct* keypress in a
	-- pane not running Neovim, and a request from Neovim reporting it hit its own edge, resolve
	-- through this same option — smart-splits.nvim's own `move.at_edge` config has no effect here:
	--   'stop'  -- pass the keystroke through to the program in the pane (default)
	--   'wrap'  -- activate the farthest pane in the opposite direction
	--   'split' -- split the current pane in that direction
	--   function(ctx) ... end -- decide yourself; see below
	at_edge = "stop",

	-- block navigation (both a direct keypress and a request from Neovim) while the current pane
	-- is zoomed in
	block_nav_on_zoom = false,

  log_level = "info", -- 'error' | 'warn' | 'info'
})

-- wezterm cli can focus panes but does not activate a different workspace.
-- The picker signals the GUI through OSC 1337; the GUI switches workspaces here.
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == 'WEZTERM_SESH_WORKSPACE' and value and value ~= '' then
    window:perform_action(act.SwitchToWorkspace { name = value }, pane)
  end
end)

-- OpenCode's TUI plugin and the Pi extension send this pane-local user var
-- when they are ready for input or need a permission decision.
local agent_alerts = {
  opencode_done = { 'OpenCode', 'Ready for input' },
  opencode_permission = { 'OpenCode', 'Waiting for permission' },
  pi_done = { 'Pi', 'Ready for input' },
}

local alert_sound = wezterm.home_dir .. '/.local/share/sounds/wezterm-agent-alert.wav'
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name ~= 'WEZTERM_AGENT_ALERT' then
    return
  end
  local alert = agent_alerts[value]
  if not alert then
    return
  end
  window:toast_notification(alert[1], alert[2], nil, 5000)
  wezterm.background_child_process({
    wezterm.home_dir .. '/.nix-profile/bin/paplay',
    alert_sound,
  })
end)

local extra_keys = {
	-- One project picker: existing workspaces/panes plus ranked zoxide directories.
	-- It runs in a temporary tab because WezTerm has no kitty-style overlay.
	{
		key = "s",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({
			args = { "fish", "-lc", "wezterm-sesh" },
		}),
	},

	-- Tabs ~= tmux windows; panes are the splits inside each tab.
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "Backspace", mods = "CTRL", action = act.SendString("\x17") },

	{ key = "Enter", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "Enter", mods = "CTRL|ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

}

-- smart_splits.apply_to_config() adds its Ctrl+hjkl / Meta+hjkl bindings above.
-- Append our other bindings instead of replacing that list.
for _, key in ipairs(extra_keys) do
  table.insert(config.keys, key)
end

return config
