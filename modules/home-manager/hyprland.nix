{builtins}: {
  programs.kitty.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      bind =
        [
          "$mod, b, exec, firefox"
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
