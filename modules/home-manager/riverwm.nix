{
  wayland.windowManager.river = {
    enable = true;
    package = null;
    systemd = {
      enable = true;
    };
    settings = {
      declare-mode = ["normal"];
      map = {
        normal = {
          "Super Q" = "close";
          "Super Return" = "spawn ghostty";
          "Control Space" = "spawn sherlock";
          "Super B" = "spawn zen-twilight";
        };
      };
    };
  };
}
