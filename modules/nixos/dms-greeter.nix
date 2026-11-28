{inputs, ...}: {
  imports = [
    inputs.dank-greeter.nixosModules.default
  ];

  programs.dms-greeter = {
    enable = true;
    compositor = {
      name = "mango";
      customConfig = ''
        # Isolated compositor config for the DMS Greeter.
      '';
    };
    configHome = "/home/mgr8";
  };
}
