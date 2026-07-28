hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

hl.on("hyprland.start", function()
  hl.exec_cmd("clipse -listen")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 32")
end)

local mod = "SUPER"

local hs = require("hyprsplit")
hs.config({ num_workspaces = 4, persistent_workspaces = true })

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = "auto", transform = 3 })

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows",    enabled = true, speed = 2, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default" })

hl.window_rule({
  name  = "pip-float",
  match = { title = "^(Picture-in-Picture|firefox)$" },
  float = true, size = "800 450", content = "video", pin = true,
})
hl.window_rule({
  name           = "suppress-maximize",
  match          = { class = ".*" },
  suppress_event = "maximize",
})
hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})
hl.window_rule({
  name = "clipse-float",
  match = { class = "(window.clipse.output)" },
  float = true, size = "622 652", stay_focused = true,
})

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Control_L + SPACE", hl.dsp.exec_cmd("sherlock"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("chromium"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("Print", hl.dsp.exec_cmd("grimblast copy area"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("ghostty --class=window.clipse.output -e clipse"))

hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))

hl.bind(mod .. " + A", hs.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + A", hs.dsp.window.move({ workspace = 1, follow = false }))
hl.bind(mod .. " + S", hs.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + S", hs.dsp.window.move({ workspace = 2, follow = false }))
hl.bind(mod .. " + D", hs.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + D", hs.dsp.window.move({ workspace = 3, follow = false }))
hl.bind(mod .. " + F", hs.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + F", hs.dsp.window.move({ workspace = 4, follow = false }))

hl.bind(mod .. " + O", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + O", hl.dsp.window.move({ monitor = "+1" }))

for i = 1, 4 do
  hl.bind(mod .. " + " .. tostring(i), hs.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. tostring(i), hs.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
