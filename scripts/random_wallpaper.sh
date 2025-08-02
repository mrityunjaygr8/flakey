#!/usr/bin/env bash

# Directory containing your wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Check if the directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Error: Wallpaper directory not found at $WALLPAPER_DIR"
  exit 1
fi

# Select a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Check if a wallpaper was found
if [ -z "$RANDOM_WALLPAPER" ]; then
  echo "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Set the wallpaper using swww
# You can customize the transition options below
swww img "$RANDOM_WALLPAPER" \
    --transition-bezier .43,1.19,1,.4 \
    --transition-type "any" \
    --transition-duration 0.7 \
    --transition-fps 60
