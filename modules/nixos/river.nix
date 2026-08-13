{
  inputs,
  pkgs,
  ...
}: {
  # System-level river (wlroots tiling compositor) session + tooling.
  # The user-facing config (keybinds, autostart, tags) lives in the
  # home-manager module (modules/home-manager/river.nix).

  # Official NixOS river module: installs the compositor and registers a
  # GDM session (pkgs.river-classic ships share/wayland-sessions/river.desktop).
  # NOTE: use river-classic (monolithic, ships riverctl), NOT mainline river
  # 0.4.x, which is non-monolithic and dropped riverctl.
  programs.river-classic = {
    enable = true;
    package = pkgs.river-classic;
    extraPackages = with pkgs; [
      wlopm # wlr-output-power-management (dpms for swayidle)
      wlsunset
    ];
  };

  # swaylock needs a pam entry so the lock screen can authenticate.
  security.pam.services.swaylock = {};
}
