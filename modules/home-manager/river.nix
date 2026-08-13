{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  # Tag bitmask for tag N (river uses 1-based bit masks: tag1=1, tag2=2, ...).
  # Each monitor has its own independent set of these tags (no plugin needed).
  masks = [1 2 4 8];

  tagBinds = variant: cmd: let
    key = i: "Mod4 ${variant} ${toString i}";
  in
    lib.listToAttrs (lib.zipListsWith (i: m: {
        name = key i;
        value = "${cmd} ${toString m}";
      }) [1 2 3 4]
      masks);
in {
  wayland.windowManager.river = {
    enable = true;
    # river/rivertile are installed system-wide (modules/nixos/river.nix).
    package = null;

    extraSessionVariables = {
      XDG_CURRENT_DESKTOP = "river";
      RIVER_SESSION = "1";
    };

    settings = {
      declare-mode = ["normal" "locked"];
      input.keyboard.layout = "in";
      set-repeat = "50 300";
      xcursor-theme = "rose-pine-cursor 32";

      # Tag model (dwm-style). Each monitor has independent tags 1-4.
      #   Mod4+<n>            : focus single tag          (dwm `view`)
      #   Mod4+Shift+<n>      : move focused window to tag (dwm `toggletag`)
      #   Mod4+Ctrl+<n>       : toggle tag into/out of view  (dwm `toggleview` — show MULTIPLE tags)
      #   Mod4+Ctrl+Shift+<n> : move window to tag AND toggle it into view
      map.normal =
        {
          "Mod4 Return" = "spawn ghostty";
          "Mod4 Q" = "close";
          "Mod4 V" = "toggle-float";
          "Mod4 F" = "toggle-fullscreen";
          "Mod4 Shift L" = "spawn swaylock -f";
          "Mod4 B" = "spawn firefox";
          "Mod4 C" = "spawn chromium";
          "Mod4 Shift V" = "spawn ghostty --class=window.clipse.output -e clipse";
          "Control Space" = "spawn sherlock";
          "Print" = "spawn grimblast copy area";

          "Mod4 H" = "focus-view left";
          "Mod4 L" = "focus-view right";
          "Mod4 J" = "focus-view down";
          "Mod4 K" = "focus-view up";

          "Mod4 Alt H" = "swap left";
          "Mod4 Alt L" = "swap right";
          "Mod4 Alt J" = "swap down";
          "Mod4 Alt K" = "swap up";

          "Mod4 O" = "focus-output next";
          "Mod4 Shift O" = "send-to-output next";
        }
        // tagBinds "" "set-focused-tags"
        // tagBinds "Shift" "set-view-tags"
        // tagBinds "Control" "toggle-view-tags"
        // tagBinds "Control Shift" "toggle-focused-tags";

      map.locked = {
        "XF86AudioRaiseVolume" = "spawn wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "spawn wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "spawn wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "spawn wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86MonBrightnessUp" = "spawn brightnessctl -e4 -n2 set 5%+";
        "XF86MonBrightnessDown" = "spawn brightnessctl -e4 -n2 set 5%-";
      };
    };

    extraConfig = ''
      # Compositor-agnostic daemons (shared with the Hyprland session).
      ${pkgs.clipse}/bin/clipse -listen &
      ${pkgs.awww}/bin/awww-daemon &
      ${pkgs.wlsunset}/bin/wlsunset -l 18.52 -L 73.85 &

      # Default tiling layout generator (ships with river-classic).
      rivertile &
    '';
  };

  # Idle handling (replaces hypridle under river). Uses wlopm for DPMS,
  # which is compositor-agnostic.
  services.swayidle = {
    enable = true;
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
      "after-resume" = "${pkgs.wlopm}/bin/wlopm --on '*'";
    };
    timeouts = [
      {
        timeout = 900;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 1200;
        command = "${pkgs.swaylock}/bin/swaylock -f && ${pkgs.wlopm}/bin/wlopm --off '*'";
        resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'";
      }
    ];
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock;
  };

  # Gate the compositor-specific home services so they only run inside the
  # session they belong to (the compositor is chosen at login, not build time).
  # hyprpolkitagent is reused in both sessions (it works on any wlroots
  # compositor), so it is deliberately not gated.
  systemd.user.services = {
    hypridle.Service.ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    swayidle.Service.ConditionEnvironment = "XDG_CURRENT_DESKTOP=river";
  };
}
