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
  programs.i3bar-river = {
    enable = true;
    settings = {
      background = "#282828ff";
      color = "#ffffffff";
      font = "Terminess Nerd Font Mono 12";
      height = 24;
      margin_bottom = 0;
      margin_left = 0;
      margin_top = 0;
      separator = "#9a8a62ff";
      "wm.river" = {
        max_tag = 6;
      };
      # command = "i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-default.toml";
    };
  };
  programs.i3status-rust = {
    enable = true;
    bars = {
      "" = {
        blocks = [
          {
            alert = 10.0;
            block = "disk_space";
            info_type = "available";
            interval = 60;
            path = "/";
            warning = 20.0;
          }
        ];
      };
      default = {
        blocks = [
          {
            alert = 10.0;
            block = "disk_space";
            info_type = "available";
            interval = 60;
            path = "/";
            warning = 20.0;
          }
          {
            block = "memory";
            format = " $icon mem_used_percents ";
            format_alt = " $icon $swap_used_percents ";
          }
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "load";
            format = " $icon $1m ";
            interval = 1;
          }
          {
            block = "sound";
          }
          {
            block = "time";
            format = " $timestamp.datetime(f:'%a %d/%m %R') ";
            interval = 60;
          }
        ];
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
          "Super B" = "spawn zen-twilight";
          "Super J" = "focus-view next";
          "Super K" = "focus-view previous";
          "Super+Shift J" = "swap next";
          "Super+Shift K" = "swap previous";
          "Super+Shift E" = "exit";
          "Super+Shift W" = "spawn ${wallpaperScript}/bin/random-wallpaper";
        };
      };
      default-layout = "rivertile";
      spawn = [
        "i3bar-river"
        "swww-daemon"
      ];
    };
  };
}
