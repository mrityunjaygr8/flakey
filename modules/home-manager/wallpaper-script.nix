{
  pkgs,
  config,
  ...
}:
pkgs.writeShellScriptBin "random-wallpaper" ''
  #!/usr/bin/env bash
  set -o pipefail
  set -eux

  # --- A BIT OF SETUP ---
  # Get the necessary binaries from the Nix store. This makes the script portable
  # and independent of the user's PATH.
  SWWW="${pkgs.swww}/bin/swww"
  FIND="${pkgs.fd}/bin/fd"
  SHUF="${pkgs.coreutils}/bin/shuf"

  # --- USER CONFIGURATION ---
  # Directory containing your wallpapers.
  # IMPORTANT: Use the full path to your home directory.
  WALLPAPER_DIR="${config.home.homeDirectory}/Pictures/Wallpapers"

  # --- SCRIPT LOGIC ---
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory not found at $WALLPAPER_DIR"
    exit 1
  fi

  # Select a random wallpaper
  RANDOM_WALLPAPER=$($FIND --type f . "$WALLPAPER_DIR"  | $SHUF -n 1)

  if [ -z "$RANDOM_WALLPAPER" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
  fi

  # Set the wallpaper using swww with a random transition
  # swww needs a running Wayland compositor and the swww-daemon (swww init)
  # The command will fail if it cannot connect to the daemon.
  $SWWW img "$RANDOM_WALLPAPER" \
      --transition-type "any" \
      --transition-duration 0.7

''
