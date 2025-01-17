{pkgs, ...}: {
  programs.hyprland.enable = true;
  environment.systemPackages = with pkgs; [
    kitty
  ];

  services.xserver.displayManager.gdm.enable = true;
}
