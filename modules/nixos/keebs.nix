{pkgs, ...}: {
  services.udev = {
    packages = with pkgs; [
      qmk
      qmk-udev-rules # the only relevant
      qmk_hid
      via
      vial
    ]; # packages
  }; # udev
}
