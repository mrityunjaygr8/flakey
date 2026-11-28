{inputs, ...}: {
  imports = [
    inputs.rex.nixosModules.default
  ];

  services.rex.enable = true;
  users.users.mgr8.extraGroups = ["rex"];
}
