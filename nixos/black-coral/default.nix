# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
    "${builtins.fetchTarball {
      url = "https://github.com/nix-community/disko/archive/refs/tags/v1.5.0.tar.gz";
      sha256 = "sha256:0bnbd7afgnf870yqs5grjb4igmvyxd64i7kjjqhhmzcp17wxw45h";
    }}/module.nix"
    ./disko-config.nix
    ../common
  ];

  networking.hostName = "black-coral";
}