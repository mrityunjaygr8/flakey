{
  pkgs,
  config,
  ...
}: let
  wallpaperScript = import ./wallpaper-script.nix {
    inherit pkgs;
    inherit config;
  };
in {
  home.packages = with pkgs; [pamixer brightnessctl lswt waybar];
  programs.i3bar-river = {
    enable = true;
    settings = {
      background = "#282828ff";
      color = "#ffffffff";
      font = "Terminess Nerd Font Mono 16";
      height = 24;
      margin_bottom = 0;
      margin_left = 0;
      margin_top = 0;
      separator = "#9a8a62ff";
      command = "i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-default.toml";
    };
  };
  programs.i3status-rust = {
    enable = true;
    bars = {
      default = {
      };
    };
  };
  wayland.windowManager.river = {
    enable = true;
    package = null;
    systemd = {
      enable = true;
    };
    extraConfig = ''
      for i in $(seq 1 9)
      do
          tags=$((1 << ($i - 1)))

          # Super+[1-9] to focus tag [0-8]
          riverctl map normal Super $i set-focused-tags $tags

          # Super+Shift+[1-9] to tag focused view with tag [0-8]
          riverctl map normal Super+Shift $i set-view-tags $tags

          # Super+Control+[1-9] to toggle focus of tag [0-8]
          riverctl map normal Super+Control $i toggle-focused-tags $tags

          # Super+Shift+Control+[1-9] to toggle tag [0-8] of focused view
          riverctl map normal Super+Shift+Control $i toggle-view-tags $tags
      done
      rivertile -view-padding 6 -outer-padding 6 &
    '';
    settings = {
      declare-mode = ["normal"];
      map = {
        normal = {
          "Super Q" = "close";
          "Super Return" = "spawn ghostty";
          "Control Space" = "spawn sherlock";
          "Super B" = "spawn 'zen-twilight -P=Default'";
          "Super N" = "spawn 'zen-twilight -P=two --name=my.zen.youtube'";
          "Super J" = "focus-view next";
          "Super K" = "focus-view previous";
          "Super+Shift J" = "swap next";
          "Super+Shift K" = "swap previous";
          "Super+Shift E" = "exit";
          "Super+Shift W" = "spawn ${wallpaperScript}/bin/random-wallpaper";

          "None XF86AudioRaiseVolume" = "spawn 'pamixer -i 5'";
          "None XF86AudioLowerVolume" = "spawn 'pamixer -d 5'";
          "None XF86AudioMute" = "spawn 'pamixer --toggle-mute'";
          "None XF86MonBrightnessUp" = "spawn 'brightnessctl set +5%'";
          "None XF86MonBrightnessDown" = "spawn 'brightnessctl set 5%-'";
        };
      };
      rule-add = [
        "-app-id 'my.zen.youtube' tags 000000100"
      ];
      border-color-focused = "0x93a1a1";
      border-color-unfocused = "0x586e75";
      border-color-urgent = "0xf6c177";
      border-width = 20;
      focus-follows-cursor = "normal";
      xcursor-theme = "'Bibata-Modern-Classic' 24";
      default-layout = "rivertile";
      spawn = [
        "i3bar-river"
        "swww-daemon"
      ];
    };
  };
}
