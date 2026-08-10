#!/usr/bin/env bash
# Prefer first Analog Stereo sink over IEC958/S/PDIF (browser sound fix pattern).
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if ! command -v pactl >/dev/null 2>&1; then
  echo "pactl not found" >&2
  exit 1
fi
SINK=$(pactl list short sinks | awk '/analog-stereo/ && !/iec958|hdmi/ {print $2; exit}')
if [[ -z "$SINK" ]]; then
  SINK=$(pactl list short sinks | awk '{print $2; exit}')
fi
[[ -n "$SINK" ]] || { echo "no sinks"; exit 1; }
pactl set-default-sink "$SINK"
pactl set-sink-mute "$SINK" 0
for i in $(pactl list short sink-inputs | awk '{print $1}'); do
  pactl move-sink-input "$i" "$SINK" 2>/dev/null || true
done
echo "default_sink=$SINK"
