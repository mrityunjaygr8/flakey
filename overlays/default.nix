# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # pyrefly 1.3.2 in the pinned nixpkgs is missing its zstd/pkg-config build
    # inputs (NixOS/nixpkgs#584733). Use the fixed build from nixpkgs-master
    # until nixos-unstable picks it up, then drop this override.
    pyrefly = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.pyrefly;

    # xan 0.61.0 in the pinned nixpkgs is missing its zstd/pkg-config build
    # inputs, so zstd-sys panics during the build. Use the fixed build from
    # nixpkgs-master until nixos-unstable picks it up, then drop this override.
    xan = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.xan;

    # iloader 2.4.1 in the pinned nixpkgs is missing aws-lc from buildInputs
    # while cargoSetupHook sets AWS_LC_SYS_USE_SYSTEM=1, so aws-lc-sys panics
    # during the build (NixOS/nixpkgs#585227). Use the fixed build from
    # nixpkgs-master until nixos-unstable picks it up, then drop this override.
    iloader = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.iloader;

    # wayle 0.7.1 in the pinned nixpkgs builds against sqlite without listing it
    # in buildInputs, so the build fails (NixOS/nixpkgs#584719, #570940). Use the
    # fixed build from nixpkgs-master until nixos-unstable picks it up, then drop
    # this override.
    wayle = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.wayle;

    # yaak 2026.8.1 in the pinned nixpkgs omits libgit2 and sqlite from
    # buildInputs, while cargoSetupHook sets LIBGIT2_NO_VENDOR=1 and
    # LIBSQLITE3_SYS_USE_PKG_CONFIG=1, so libgit2-sys aborts the build
    # (NixOS/nixpkgs#585106). Drop this override once the fix lands in
    # nixos-unstable.
    yaak = prev.yaak.overrideAttrs (old: {
      buildInputs = (old.buildInputs or []) ++ [prev.libgit2 prev.sqlite];
    });

    # wf-recorder doesn't compile against FFmpeg 9 (removed AVCodec fields).
    # Patch from Arch Linux to use avcodec_get_supported_config().
    wf-recorder = prev.wf-recorder.overrideAttrs (old: {
      patches =
        (old.patches or [])
        ++ [
          ../patches/wf-recorder-ffmpeg9.patch
        ];
    });
  };
}
