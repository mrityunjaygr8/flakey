{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    # gnomeExtensions.pano
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.space-bar
    gnomeExtensions.just-perfection
    gnomeExtensions.paperwm
    gnomeExtensions.forge
    gnomeExtensions.tiling-assistant
  ];
  services.udev.packages = with pkgs; [gnome-settings-daemon];
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = {
          "org/gnome/shell".enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            # "pano@elhan.io"
            "space-bar@luchrioh"
            "Vitals@CoreCoding.com"
          ];
        };
      }
    ];
  };
}
