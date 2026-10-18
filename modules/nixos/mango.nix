{
  inputs,
  pkgs,
  ...
}: let
  mangoPackage = pkgs.callPackage ../../pkgs/mango-dms-compat.nix {
    mango = inputs.mangowm.packages.${pkgs.stdenv.hostPlatform.system}.mango;
  };
in {
  imports = [
    inputs.mangowm.nixosModules.mango
  ];

  programs.mango = {
    enable = true;
    package = mangoPackage;
  };
}
