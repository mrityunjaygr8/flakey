{pkgs, ...}: {
  environment.systemPackages = with pkgs; [vial];
  services.udev = {
    enable = true;
    packages = with pkgs; [
      qmk
      qmk-udev-rules # the only relevant
      qmk_hid
      via
      vial
    ]; # packages
  }; # udev
}
