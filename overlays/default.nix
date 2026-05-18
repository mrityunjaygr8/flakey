# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    bun = let
      version = "1.3.13";
    in
      prev.bun.overrideAttrs (oldAttrs: {
        version = version;
        src = final.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          # Set to empty string first, run build, then copy the "got" hash here
          hash = "sha256-ecB3H6i5LDOq5B4VoODTB+qZ0OLwAxfHHGxTI3p44lo=";
        };
      });
    hyprlandPlugins =
      prev.hyprlandPlugins
      // {
        hyprsplit = let
          version = "0.54.2";
          commit = "ea230fc65b4bd591451d2305140a2e3fbce894ca";
        in
          prev.hyprlandPlugins.hyprsplit.overrideAttrs (oldAttrs: {
            # patches =
            #   (oldAttrs.patches or [])
            #   ++ [
            #     (final.fetchpatch {
            #       # Replace 12345 with the actual PR number you are tracking
            #       url = "https://github.com/NixOS/nixpkgs/pull/486486.diff";
            #       # Initial hash - change this after the first failed build attempt
            #       hash = "sha256-DUQXnZhejpVgSKRoQozNxxFUHiEvztdUCk3bA3AKsmA=";
            #     })
            #   ];
            version = version;
            src = final.fetchFromGitHub {
              owner = "shezdy";
              repo = "hyprsplit";
              # tag = "v${version}";
              rev = commit;
              hash = "sha256-VeVHk55Vg9+0BfUS+GleE7vZfa7ssb4yM+p+noJ349w=";
            };
          });
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
