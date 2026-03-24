# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    bun = let
      version = "1.3.11";
    in
      prev.bun.overrideAttrs (oldAttrs: {
        version = version;
        src = final.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          # Set to empty string first, run build, then copy the "got" hash here
          hash = "sha256-hhG6k1r4hvBabzh0ChUWAybBXl1dB63vlmEwtEk2B+0=";
        };
      });
    hyprlandPlugins =
      prev.hyprlandPlugins
      // {
        hyprsplit = let
          version = "0.54.2";
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
              tag = "v${version}";
              hash = "sha256-NFMLZmM6lM7v6WFcewOp7pKPlr6ampX/MB/kGxt/gPE=";
            };
          });
      };
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    # opencode = prev.opencode.overrideAttrs (oldAttrs: rec {
    #   version = "0.14.3";
    #   src = prev.fetchFromGitHub {
    #     inherit (oldAttrs.src) owner repo;
    #     rev = "v${version}";
    #     sha256 = "sha256-cJKUaLIWexpG9Gz6ASIZ4SyoUe+1Ljf5pj/veyBi7Lg=";
    #   };
    #
    #   tui = prev.buildGoModule {
    #     inherit (oldAttrs.tui) name src modRoot subPackages ldflags installPhase;
    #     vendorHash = "sha256-H+TybeyyHTbhvTye0PCDcsWkcN8M34EJ2ddxyXEJkZI=";
    #   };
    #   node_modules = prev.stdenvNoCC.mkDerivation {
    #     inherit (oldAttrs.node_modules) name impureEnvVars nativeBuildInputs dontConfigure buildPhase installPhase dontFixup outputHashMode outputHashAlgo;
    #
    #     outputHash = "sha256-p01odCHK8++numXipx1p9qJ+bvZuGjBnV9GZRg0iQLY=";
    #   };
    # });
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
