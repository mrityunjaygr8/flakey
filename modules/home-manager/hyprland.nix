{
  inputs,
  pkgs,
  config,
  ...
}: let
  fixedSizeFloatScript = pkgs.writeShellScriptBin "fixed-size-float" ''
    set -o pipefail
    set -eux

    WIDTH=1280
    HEIGHT=720

    ADDR=$(hyprctl activewindow -j | jq -r '.address')

    hyprctl dispatch setfloating address:$ADDR
    hyprctl dispatch resizewindowpixel exact $WIDTH $HEIGHT,address:$ADDR
    hyprctl dispatch centerwindow address:0x$ADDR
  '';
  wallpaperScript = pkgs.writeShellScriptBin "random-wallpaper" ''
    #!/usr/bin/env bash
    set -o pipefail
    set -eux

    # --- A BIT OF SETUP ---
    # Get the necessary binaries from the Nix store. This makes the script portable
    # and independent of the user's PATH.
    AWWW="${pkgs.awww}/bin/awww"
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

    # Set the wallpaper using awww with a random transition
    # awww needs a running Wayland compositor and the awww-daemon (awww init)
    # The command will fail if it cannot connect to the daemon.
    $AWWW img "$RANDOM_WALLPAPER" \
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
    awww
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
      # Run 1 second after boot/login
      OnBootSec = "1seconds";
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
  services.wayle = {
    enable = true;
    autoInstallDependencies = true;
    settings = {
      bar = {
        button-variant = "basic";
        layout = [
          # add more attribute sets with different monitors if wayle should
          # have different layouts on each
          {
            monitor = "*"; # replace "DP-1" with "*" for all monitors
            show = true;
            center = [
              "notifications"
              "window-title"
            ];
            left = ["dashboard" "custom-workspaces"];
            right = ["microphone" "volume" "bluetooth" "network" "cpu" "ram" "brightness" "battery" "weather" "clock"];
          } # this is a 'list' of 'attribute sets', no semi-colons after the closing braces needed
        ];
      };
      modules = {
        clock = {
          format = "%H:%M:%S";
          dropdown-show-seconds = false;
        };
        weather = {
          location = "Pune";
          units = "metric";
        };
      };
      osd = {
        monitor = "DP-1";
      };
    };
  };
  # programs.hyprpanel = {
  #   enable = true;
  #   # Configure and theme almost all options from the GUI.
  #   # See 'https://hyprpanel.com/configuration/settings.html'.
  #   # Default: <same as gui>
  #   settings = {
  #     # Configure bar layouts for monitors.
  #     # See 'https://hyprpanel.com/configuration/panel.html'.
  #     # Default: null
  #     layout = {
  #       bar.layouts = {
  #         "0" = {
  #           left = ["dashboard" "workspaces"];
  #           middle = ["media"];
  #           right = ["volume" "systray" "notifications"];
  #         };
  #       };
  #     };
  #
  #     bar.launcher.autoDetectIcon = true;
  #     bar.workspaces.show_icons = true;
  #
  #     menus.clock = {
  #       time = {
  #         military = true;
  #         hideSeconds = true;
  #       };
  #       weather.unit = "metric";
  #     };
  #
  #     menus.dashboard.directories.enabled = false;
  #     menus.dashboard.stats.enable_gpu = true;
  #
  #     theme.bar.transparent = true;
  #
  #     theme.font = {
  #       name = "CaskaydiaCove NF";
  #       size = "16px";
  #     };
  #   };
  # };
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
    configType = "lua";
    package = null;
    portalPackage = null;
    enable = true;
    systemd.variables = ["--all"];
    extraLuaFiles = {
      "hyprsplit/init" = {
        autoLoad = false;
        content = builtins.readFile "${inputs.hyprsplit.packages.${pkgs.system}.hyprsplitlua}/share/hyprsplit/init.lua";
      };
      "hyprload" = {
        autoLoad = true;
        content =
          builtins.readFile ../../config/hyprland/default.lua
          + ''
            hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("${wallpaperScript}/bin/random-wallpaper"))
            hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("${fixedSizeFloatScript}/bin/fixed-size-float"))
          '';
      };
    };
  };
}
