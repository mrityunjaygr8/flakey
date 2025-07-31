{pkgs, ...}: {
  programs.kitty.enable = true; # required for the default Hyprland config
  home.packages = with pkgs; [
    grimblast
    brightnessctl
    walker
    pipewire
    wireplumber
    fastfetch
  ];
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
    settings = {
      "exec-once" = [
        # "waybar"
        "hyprpanel"
        "systemctl --user start hyprpolkitagent"
        # "dunst"
      ];
      "$mod" = "SUPER";
      monitor = ",preffered,auto,1";
      windowrule = [
        # Ignore maximize requests from apps. You'll probably like this.
        "suppressevent maximize, class:.*"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
      bind =
        [
          "Control_L,SPACE,exec,anyrun"
          "$mod, Q, killactive"
          "$mod, V, togglefloating"
          "$mod, RETURN, exec, ghostty"
          "$mod, B, exec, zen-twilight"
          "$mod, C, exec, chromium"
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
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            8)
        );
    };
  };
}
