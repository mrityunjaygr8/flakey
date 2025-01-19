let
  number_letter_mapping = {
    "1" = "a";
    "2" = "s";
    "3" = "d";
    "4" = "f";
    "5" = "g";
  };
in
  {pkgs, ...}: {
    imports = [
      ./gtk.nix
      ./waybar.nix
    ];

    home.packages = with pkgs; [
      hyprpolkitagent
    ];

    services.mako.enable = true;
    programs.wofi.enable = true;
    programs.kitty.enable = true;
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        "$terminal" = "ghostty";
        "$browser" = "firefox";
        "$menu" = "wofi --show drun";
        "exec-once" = [
          "systemctl --user start hyprpolkitagent"
          "waybar & mako"
        ];
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];
        monitor = [
          "desc:Dell Inc. DELL P2419H C5WWLV2, preferred, auto, 1, transform, 3"
          ", preferred, auto, 1"
        ];
        animations = {
          enabled = false;
        };
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
            "$mod, M, togglespecialworkspace, magic"
            "$mod SHIFT, M, movetoworkspace, special:magic"
          ]
          ++ (
            builtins.concatLists (builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "$mod,${builtins.getAttr (toString ws) number_letter_mapping}, workspace, ${toString ws}"
                  "$mod SHIFT,${builtins.getAttr (toString ws) number_letter_mapping}, movetoworkspace, ${toString ws}"
                ]
              )
              5)
          );
      };
    };

    home.sessionVariables.NIXOS_OZONE_WL = "1";
  }
