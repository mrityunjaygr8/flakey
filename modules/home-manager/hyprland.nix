{pkgs, ...}: {
  imports = [
    ./gtk.nix
  ];

  home.packages = with pkgs; [
    hyprpolkitagent
    dunst
    wofi
  ];

  programs.kitty.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "firefox";
      "$menu" = "wofi --show drun";
      "exec-once" = "systemctl --user start hyprpolkitagent";
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];
      bind =
        [
          "$mod, B, exec, $browser"
          "$mod, RETURN, exec, $terminal"
          "$mod, Q, exec, kitty"
          "$mod SHIFT, C, killactive"
          "$mod, V, togglefloating"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"
          "$mod, R, exec, $menu"
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"
        ]
        ++ (
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod,code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
    };
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
