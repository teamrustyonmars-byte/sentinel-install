#!/usr/bin/env bash
# upgrade then full-upgrade if leftovers remain (no auto-reboot).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
SUDO="sudo -n"
$SUDO true 2>/dev/null || SUDO="sudo"
$SUDO apt-get update -qq
$SUDO apt-get upgrade -y
# if still upgradable, full-upgrade
LEFT=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
if [[ "${LEFT// /}" -gt 0 ]]; then
  echo "leftover=$LEFT → full-upgrade"
  $SUDO apt-get full-upgrade -y
fi
echo "done $(hostname); reboot-required=$([[ -f /var/run/reboot-required ]] && echo yes || echo no)"
