{
  inputs,
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
  # imports = [
  #   inputs.sherlock.homeModules.default
  # ];
  programs.kitty.enable = true; # required for the default Hyprland config
  home.packages = with pkgs; [
    hyprshot
    grimblast
    brightnessctl
    walker
    pipewire
    wf-recorder
    pulseaudio # used for hyprpanel screen record script
    wireplumber
    fastfetch
    swww
    fd
    rose-pine-hyprcursor
    hyprcursor
    nwg-look
    hyprsunset
    clipse
  ];
  programs.sherlock = {
    enable = true;
    settings = {
      config = {};
      launchers = [
        {
          name = "App Launcher";
          type = "app_launcher";
          args = {};
          priority = 1;
          home = true;
        }
      ];
    };
  };
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
      # Run every 2 minutes thereafter
      OnUnitActiveSec = "2min";
      Unit = "wallpaper-changer.service";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "hyprlock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
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
  xdg.configFile = {
    "hypr/hyprsunset.conf" = {
      enable = true;
      text = ''
        max-gamma = 150
        profile {
          time = 7:30
          identity = true
        }

        profile {
          time = 20:00
          temperature = 4500
          gamma = 0.8
        }

      '';
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
    plugins = [pkgs.hyprlandPlugins.hyprsplit];
    settings = {
      env = ["HYPRCURSOR_THEME,rose-pine-hyprcursor"];
      "exec-once" = [
        # "waybar"
        "clipse -listen"
        "hyprsunset"
        "hypridle"
        "hyprpanel"
        "systemctl --user start hyprpolkitagent"
        "swww-daemon"
        "hyprctl setcursor rose-pine-hyprcursor 32"
        # "dunst"
      ];
      "$mod" = "SUPER";
      plugin = {
        hyprsplit = {
          num_workspaces = 4;
          persistent_workspaces = true;
        };
      };
      windowrulev2 =
        [
          # These rules are for pinning the Picture-in-Picture window
          "float, title:^(Picture-in-Picture|firefox)$"
          "size 800 450,title:^(Picture-in-Picture|firefox)$"
          "content video,title:^(Picture-in-Picture|firefox)$"
          "pin, title:^(Picture-in-Picture|firefox)$"
        ]
        ++
        # For the clipboard TUI
        [
          "float, class:(window.clipse.output)"
          "size 622 652, class:(window.clipse.output)"
          "stayfocused, class:(window.clipse.output)"
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
        "suppress_event maximize, match:class .*"

        # Fix some dragging issues with XWayland
        "no_focus on,match:class ^$,match:title ^$,match:xwayland 1,match:float 1,match:fullscreen 0,match:pin 0"
      ];
      bindm =
        # Move/resize windows with mainMod + LMB/RMB and dragging
        [
          "$mod,mouse:272, movewindow"
          "$mod,mouse:273, resizewindowpixel"
        ];
      bind =
        [
          "Control_L,SPACE,exec,sherlock"
          "$mod, Q, killactive"
          "$mod, V, togglefloating"
          "$mod, RETURN, exec, [workspace 1 silent] ghostty"
          "$mod, B, exec, firefox"
          "$mod, C, exec, chromium"
          "$mod SHIFT, L, exec, hyprlock"
          "$mod SHIFT, W, exec, ${wallpaperScript}/bin/random-wallpaper"
          ", Print, exec, grimblast copy area"
        ]
        ++ [
          "$mod SHIFT, V, exec, ghostty --class=window.clipse.output -e clipse"
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
        # Switching workspaces using ASDF
        [
          "$mod, A, split:workspace, 1"
          "$mod SHIFT, A, split:movetoworkspacesilent, 1"
          "$mod, S, split:workspace, 2"
          "$mod SHIFT, S, split:movetoworkspacesilent, 2"
          "$mod, D, split:workspace, 3"
          "$mod SHIFT, D, split:movetoworkspacesilent, 3"
          "$mod, F, split:workspace, 4"
          "$mod SHIFT, F, split:movetoworkspacesilent, 4"
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
