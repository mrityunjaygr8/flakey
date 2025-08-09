{
  pkgs,
  config,
  ...
}: let
  wallpaperScript = import ./wallpaper-script.nix;
in {
  home.packages = with pkgs; [swww bibata-cursors];
  systemd.user.services.wallpaper-changer = {
    Unit = {
      Description = "Change wallpaper periodically";
    };
    Service = {
      Type = "oneshot";
      # This points to the script we defined above in the `let` block.
      ExecStart = "${wallpaperScript.wallpaperScript}/bin/random-wallpaper";
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
}
