# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#<name>'
pkgs: {
  iloader = pkgs.callPackage ./iloader.nix {};
}
