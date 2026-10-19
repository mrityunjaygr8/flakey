{ inputs, ... }: {
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;
    # Mango starts DMS through autostart_sh; do not start a second service.
    systemd.enable = false;

    # Keep the complete current settings (including configVersion 18 and the
    # layout widget) as version-controlled input. Home Manager generates the
    # managed settings.json from this attribute set.
    settings =
      builtins.fromJSON (
        builtins.readFile ../../config/dank-material-shell/settings.json
      );
  };
}
