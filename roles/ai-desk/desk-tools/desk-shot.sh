#!/usr/bin/env bash
# Screenshot active display (requires scrot or import). Scrubbed desk helper.
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
OUT="${1:-$HOME/.local/share/desk-tools/out/shot-latest.jpg}"
mkdir -p "$(dirname "$OUT")"
if command -v scrot >/dev/null 2>&1; then
  scrot -o "$OUT"
elif command -v import >/dev/null 2>&1; then
  import -window root "$OUT"
else
  echo "install scrot or imagemagick" >&2
  exit 1
fi
echo "$OUT"
