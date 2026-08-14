# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # wf-recorder doesn't compile against FFmpeg 9 (removed AVCodec fields).
    # Patch from Arch Linux to use avcodec_get_supported_config().
    wf-recorder = prev.wf-recorder.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ../patches/wf-recorder-ffmpeg9.patch
      ];
    });
    # calibre doesn't compile against FFmpeg 9 (removed AVCodec fields)
    calibre = prev.calibre.override {
      ffmpeg = prev.ffmpeg_6;
    };
  };
}
