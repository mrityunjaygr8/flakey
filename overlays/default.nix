# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # hyprlandPlugins =
    #   prev.hyprlandPlugins
    #   // {
    #     hyprsplit = prev.hyprlandPlugins.hyprsplit.overrideAttrs (oldAttrs: rec {
    #       version = "0.53.1";
    #       src = final.fetchFromGitHub {
    #         owner = "shezdy";
    #         repo = "hyprsplit";
    #         rev = "v${version}"; # Or use a specific commit hash
    #         # Leave this hash empty or use lib.fakeHash first;
    #         # Nix will error and give you the correct one.
    #         hash = "sha256-seA9mz0Yej4yYZVgzd7yKoHwuueKhfQPu0CyB7EL8No=";
    #       };
    #     });
    #   };
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
