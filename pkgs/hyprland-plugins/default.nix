{
  config,
  lib,
  callPackage,
  pkg-config,
  hyprland,
} @ topLevelArgs: let
  mkHyprlandPlugin = lib.extendMkDerivation {
    constructDrv = topLevelArgs.hyprland.stdenv.mkDerivation;

    extendDrvArgs = finalAttrs: {
      pluginName ? "",
      nativeBuildInputs ? [],
      buildInputs ? [],
      hyprland ? topLevelArgs.hyprland,
      ...
    } @ args: {
      pname = "${pluginName}";
      nativeBuildInputs = [pkg-config] ++ nativeBuildInputs;
      buildInputs = [hyprland] ++ hyprland.buildInputs ++ buildInputs;
      meta =
        args.meta
        // {
          description = args.meta.description or "";
          longDescription =
            (args.meta.longDescription or "")
            + "\n\nPlugins can be installed via a plugin entry in the Hyprland NixOS or Home Manager options.";

          platforms = args.meta.platforms or hyprland.meta.platforms or [];
        };
    };
  };

  plugins = lib.mergeAttrsList [
    {hyprsplit = import ./hyprsplit.nix;}
    (import ./hyprland-plugins.nix)
  ];
in
  (lib.mapAttrs (name: plugin: callPackage plugin {inherit mkHyprlandPlugin;}) plugins)
  // {
    inherit mkHyprlandPlugin;
  }
