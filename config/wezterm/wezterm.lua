local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Use the GCR agent from the graphical session as WezTerm's mux agent source.
-- Without this, panes can inherit a WezTerm agent socket with no backing agent.
local runtime_dir = os.getenv("XDG_RUNTIME_DIR")
if runtime_dir then
	config.default_ssh_auth_sock = runtime_dir .. "/gcr/ssh"
end

-- Explicitly use Fish as the login shell for new WezTerm panes/tabs.
config.default_prog = { 'fish', '-l' }

-- Mirror the kitty trial so the terminal itself is the main variable.
config.font = wezterm.font("Lilex Nerd Font Mono")
config.font_size = 16
config.color_scheme = "Ayu Mirage"
config.scrollback_lines = 10000

-- Keep the tab bar visible: tabs are the tmux-window-like layer, panes are splits.
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- The fancy tab bar draws its own chrome from the window frame colours, so tint
-- it to match Ayu Mirage instead of falling back to WezTerm's default purple.
config.window_frame = {
	font = wezterm.font({ family = "Lilex Nerd Font Mono", weight = "Bold" }),
	font_size = 12.0,
	active_titlebar_bg = "#1f2430",
	inactive_titlebar_bg = "#1f2430",
	active_titlebar_fg = "#cbccc6",
	inactive_titlebar_fg = "#707a8c",
	active_titlebar_border_bottom = "#2a3040",
	inactive_titlebar_border_bottom = "#1f2430",
	button_fg = "#707a8c",
	button_bg = "#1f2430",
	button_hover_fg = "#cbccc6",
	button_hover_bg = "#2a3040",
}

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
		-- Not META/SUPER: Mango consumes SUPER+hjkl globally for focusdir, so
		-- resize chords never reached WezTerm. CTRL|SHIFT is otherwise free
		-- (the other CTRL|SHIFT binds use s/t/w/Tab/Enter/arrows).
		resize = "CTRL|SHIFT", -- e.g. CTRL+SHIFT+h to resize left
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
-- when they are ready for input or need a permission decision. The value is
-- base64-encoded JSON: { alert, session?, pid? }.
local agent_alerts = {
  opencode_done = { 'OpenCode', 'Ready for input' },
  opencode_permission = { 'OpenCode', 'Waiting for permission' },
  pi_done = { 'Pi', 'Ready for input' },
}

local alert_sound = wezterm.home_dir .. '/.local/share/sounds/wezterm-agent-alert.wav'

-- $XDG_RUNTIME_DIR is per-login and cleared automatically, so unread markers
-- don't survive a reboot. wezterm-sesh reads this same file.
local alert_state_file = (runtime_dir or (wezterm.home_dir .. '/.cache'))
  .. '/wezterm-agent-alerts.json'

local function read_alerts()
  local file = io.open(alert_state_file, 'r')
  if not file then
    return {}
  end
  local content = file:read('*a')
  file:close()
  local ok, decoded = pcall(wezterm.json_parse, content)
  if ok and type(decoded) == 'table' then
    return decoded
  end
  return {}
end

local function write_alerts(alerts)
  local tmp = alert_state_file .. '.tmp'
  local file = io.open(tmp, 'w')
  if not file then
    return
  end
  file:write(wezterm.json_encode(alerts))
  file:close()
  os.rename(tmp, alert_state_file)
end

local function clear_alert(pane_id)
  local alerts = read_alerts()
  if alerts[pane_id] ~= nil then
    alerts[pane_id] = nil
    write_alerts(alerts)
  end
end

local function decode_alert(value)
  local ok, parsed = pcall(wezterm.json_parse, value)
  if ok and type(parsed) == 'table' then
    return parsed.alert, parsed.session, parsed.pid
  end
  return value, nil, nil
end

wezterm.on('user-var-changed', function(window, pane, name, value)
  if name ~= 'WEZTERM_AGENT_ALERT' then
    return
  end
  local kind, session, pid = decode_alert(value)
  local alert = agent_alerts[kind]
  if not alert then
    return
  end

  -- Only record an unread marker when the user isn't already looking at the
  -- pane. The toast and sound still fire either way.
  local active_pane = window:active_pane()
  local focused = window:is_focused()
    and active_pane ~= nil
    and active_pane:pane_id() == pane:pane_id()
  if not focused then
    local alerts = read_alerts()
    local record = {
      alert = kind,
      session = type(session) == 'string' and session or '',
      updated = os.time(),
    }
    if type(pid) == 'number' then
      record.pid = pid
    end
    alerts[tostring(pane:pane_id())] = record
    write_alerts(alerts)
  end

  local title = alert[1]
  if type(session) == 'string' and session ~= '' then
    title = title .. ' · ' .. session
  end
  window:toast_notification(title, alert[2], nil, 5000)
  wezterm.background_child_process({
    wezterm.home_dir .. '/.nix-profile/bin/paplay',
    alert_sound,
  })
end)

-- Copy mode is a pane-local key table, so entering it by accident (Ctrl+Shift+X,
-- or the plain Ctrl+X alias) leaves the terminal looking normal while typing no
-- longer reaches Fish. Flag it in two places, since either can be missed:
--   1. the tab itself turns amber (works with the fancy tab bar),
--   2. a badge on the right of the tab bar.
-- The fancy tab bar ignores color-scheme tab_bar colors but does honour
-- format-tab-title styling, hence the amber tab below.
config.status_update_interval = 500

local mode_colors = {
	copy_mode = { bg = "#ffb454", fg = "#1b1f27", label = " COPY " },
	search_mode = { bg = "#95e6cb", fg = "#1b1f27", label = " SEARCH " },
}

-- Fancy tab bar calls this twice per tab, so keep it cheap and side-effect free.
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
	local title = tab.tab_title
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	-- Copy mode prefixes the pane title with "Copy mode: "; strip it so the
	-- badge below carries that meaning instead of duplicating it.
	title = title:gsub('^Copy mode: ', '')

	local mode = nil
	for _, pane in ipairs(tab.panes) do
		local pane_title = pane.title or ''
		if pane_title:match('^Copy mode: ') then
			mode = mode_colors.copy_mode
			break
		elseif pane_title:match('^Search: ') then
			mode = mode_colors.search_mode
		end
	end

	if mode then
		return {
			{ Background = { Color = mode.bg } },
			{ Foreground = { Color = mode.fg } },
			{ Attribute = { Intensity = 'Bold' } },
			{ Text = ' ' .. title .. ' ' },
		}
	end
end)

-- WezTerm has no pane-focus-changed event, so derive it from update-status.
-- An alert is unread until its pane is focused; this also handles switching
-- tabs/workspaces and returning to a background window.
local focused_panes = {}
wezterm.on('update-status', function(window, pane)
	local window_id = tostring(window:window_id())
	local pane_id = tostring(pane:pane_id())
	local is_focused = window:is_focused()
	local previous = focused_panes[window_id]

	if is_focused and (not previous or not previous.focused or previous.pane ~= pane_id) then
		clear_alert(pane_id)
	end
	focused_panes[window_id] = { focused = is_focused, pane = pane_id }

	local active = window:active_key_table()
	local mode = mode_colors[active or '']
	if not mode then
		window:set_right_status('')
		return
	end

	window:set_right_status(wezterm.format({
		{ Background = { Color = mode.bg } },
		{ Foreground = { Color = mode.fg } },
		{ Attribute = { Intensity = 'Bold' } },
		{ Text = mode.label },
	}))
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
