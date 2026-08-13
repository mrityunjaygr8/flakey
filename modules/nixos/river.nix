{
  inputs,
  pkgs,
  ...
}: {
  # System-level river (wlroots tiling compositor) session + tooling.
  # The user-facing config (keybinds, autostart, tags) lives in the
  # home-manager module (modules/home-manager/river.nix).

  # Official NixOS river module: installs the compositor and registers a
  # GDM session (pkgs.river ships share/wayland-sessions/river.desktop).
  programs.river-classic = {
    enable = true;
    package = pkgs.river;
    extraPackages = with pkgs; [
      rivercarro # tiling layout generator (maintained fork of rivertile)
      wlopm # wlr-output-power-management (dpms for swayidle)
      wlsunset
    ];
  };

  # swaylock needs a pam entry so the lock screen can authenticate.
  security.pam.services.swaylock = {};
}
