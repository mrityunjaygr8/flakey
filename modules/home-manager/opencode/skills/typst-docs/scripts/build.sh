#!/usr/bin/env bash
# Build a Typst document with the home-manager font paths.
# Usage: build.sh <doc.typ> [out.pdf]
set -euo pipefail

src="${1:?usage: build.sh <doc.typ> [out.pdf]}"
out="${2:-${src%.typ}.pdf}"

typst compile \
  --font-path "$HOME/.nix-profile/share/fonts" \
  --font-path "$HOME/.local/share/fonts" \
  "$src" "$out"

echo "wrote $out"
