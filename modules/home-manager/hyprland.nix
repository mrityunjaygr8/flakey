{
  pkgs,
  config,
  ...
}: let
  wallpaperScript = pkgs.writeShellScriptBin "random-wallpaper" ''
    #!/usr/bin/env bash
    set -o pipefail
    set -eux

    # --- A BIT OF SETUP ---
    # Get the necessary binaries from the Nix store. This makes the script portable
    # and independent of the user's PATH.
    SWWW="${pkgs.swww}/bin/swww"
    FIND="${pkgs.fd}/bin/fd"
    SHUF="${pkgs.coreutils}/bin/shuf"

    # --- USER CONFIGURATION ---
    # Directory containing your wallpapers.
    # IMPORTANT: Use the full path to your home directory.
    WALLPAPER_DIR="${config.home.homeDirectory}/Pictures/Wallpapers"

    # --- SCRIPT LOGIC ---
    if [ ! -d "$WALLPAPER_DIR" ]; then
      echo "Error: Wallpaper directory not found at $WALLPAPER_DIR"
      exit 1
    fi

    # Select a random wallpaper
    RANDOM_WALLPAPER=$($FIND --type f . "$WALLPAPER_DIR"  | $SHUF -n 1)

    if [ -z "$RANDOM_WALLPAPER" ]; then
      echo "No wallpapers found in $WALLPAPER_DIR"
      exit 1
    fi

    # Set the wallpaper using swww with a random transition
    # swww needs a running Wayland compositor and the swww-daemon (swww init)
    # The command will fail if it cannot connect to the daemon.
    $SWWW img "$RANDOM_WALLPAPER" \
        --transition-type "any" \
        --transition-duration 0.7

  '';
in {
  programs.kitty.enable = true; # required for the default Hyprland config
  home.packages = with pkgs; [
    grimblast
    brightnessctl
    walker
    pipewire
    wireplumber
    fastfetch
    swww
    fd
  ];
  systemd.user.services.wallpaper-changer = {
    Unit = {
      Description = "Change wallpaper periodically";
    };
    Service = {
      Type = "oneshot";
      # This points to the script we defined above in the `let` block.
      ExecStart = "${wallpaperScript}/bin/random-wallpaper";
    };
  };
  systemd.user.timers.wallpaper-changer = {
    Unit = {
      Description = "Timer for changing wallpaper";
    };
    Timer = {
      # Run 1 minute after boot/login
      OnBootSec = "1min";
      # Run every 30 minutes thereafter
      OnUnitActiveSec = "5min";
      Unit = "wallpaper-changer.service";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
  programs.hyprpanel = {
    enable = true;
    # Configure and theme almost all options from the GUI.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {
      # Configure bar layouts for monitors.
      # See 'https://hyprpanel.com/configuration/panel.html'.
      # Default: null
      layout = {
        bar.layouts = {
          "0" = {
            left = ["dashboard" "workspaces"];
            middle = ["media"];
            right = ["volume" "systray" "notifications"];
          };
        };
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = true;

      menus.clock = {
        time = {
          military = true;
          hideSeconds = true;
        };
        weather.unit = "metric";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = true;

      theme.bar.transparent = true;

      theme.font = {
        name = "CaskaydiaCove NF";
        size = "16px";
      };
    };
  };
  programs.anyrun = {
    enable = true;
    config = {
      x = {fraction = 0.5;};
      y = {fraction = 0.3;};
      width = {fraction = 0.3;};
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;
      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/libsymbols.so"
        "${pkgs.anyrun}/lib/librink.so"
        "${pkgs.anyrun}/lib/libtranslate.so"
        "${pkgs.anyrun}/lib/libkidex.so"
        "${pkgs.anyrun}/lib/librandr.so"
        "${pkgs.anyrun}/lib/libwebsearch.so"
      ];
    };
  };
  services.hyprpolkitagent.enable = true;
  programs.hyprlock.enable = true;
  wayland.windowManager.hyprland = {
    ### Using the package from nixos module for betting setting up
    package = null;
    portalPackage = null;
    enable = true;
    systemd.variables = ["--all"];
    plugins = with pkgs; [hyprlandPlugins.hyprsplit];
    settings = {
      "exec-once" = [
        # "waybar"
        "hyprpanel"
        "systemctl --user start hyprpolkitagent"
        "swww-daemon"
        # "dunst"
      ];
      "$mod" = "SUPER";
      plugin = {
        hyprsplit = {
          num_workspaces = 4;
          persistent_workspaces = true;
        };
      };
      windowrulev2 = [
        # These rules are for pinning the Picture-in-Picture window
        "float, title:^(Picture-in-Picture|zen-twilight)$"
        "size 800 450,title:^(Picture-in-Picture|zen-twilight)$"
        "content video,title:^(Picture-in-Picture|zen-twilight)$"
        "pin, title:^(Picture-in-Picture|zen-twilight)$"
      ];
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 2, myBezier"
          "windowsOut, 1, 2, default, popin 80%"
          "border, 1, 3, default"
          "fade, 1, 2, default"
          "workspaces, 1, 2, default"
        ];
      };
      monitor = [",preffered,auto,1" "DP-2,preffered,auto,1,transform,3"];
      windowrule = [
        # Ignore maximize requests from apps. You'll probably like this.
        "suppressevent maximize, class:.*"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
      bindm =
        # Move/resize windows with mainMod + LMB/RMB and dragging
        [
          "$mod,mouse:272, movewindow"
          "$mod,mouse:273, resizewindowpixel"
        ];
      bind =
        [
          "Control_L,SPACE,exec,anyrun"
          "$mod, Q, killactive"
          "$mod, V, togglefloating"
          "$mod, RETURN, exec, ghostty"
          "$mod, B, exec, zen-twilight"
          "$mod, C, exec, chromium"
          "$mod SHIFT, L, exec, hyprlock"
          "$mod SHIFT, W, exec, ${wallpaperScript}/bin/random-wallpaper"
          ", Print, exec, grimblast copy area"
        ]
        ++
        # Focus Switching keybinds
        [
          "$mod,h,movefocus,l"
          "$mod,l,movefocus,r"
          "$mod,j,movefocus,d"
          "$mod,k,movefocus,u"
        ]
        ++
        # Swap focus and windows between monitors
        [
          "$mod, O, focusmonitor, +1"
          "$mod SHIFT, O, movewindow, mon:+1"
        ]
        ++
        # Volume Stuff
        [
          # Laptop multimedia keys for volume and LCD brightness
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, split:workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, split:movetoworkspacesilent, ${toString ws}"
              ]
            )
            4)
        );
    };
  };
}
