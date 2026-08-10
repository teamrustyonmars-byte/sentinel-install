#!/usr/bin/env bash
# Report upgradable / kept-back / reboot hints (read-only-ish; runs apt update).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
if ! command -v apt-get >/dev/null 2>&1; then
  echo "not a Debian/Ubuntu host"; exit 0
fi
sudo -n apt-get update -qq 2>/dev/null || apt-get update -qq 2>/dev/null || true
echo "=== $(hostname) $(date -u +%Y-%m-%dT%H:%MZ) ==="
echo "-- upgradable --"
apt list --upgradable 2>/dev/null | tail -n +2 || true
echo "-- kept back (heuristic) --"
apt-get upgrade --dry-run 2>/dev/null | grep -i 'kept back' || echo "(none noted)"
if [[ -f /var/run/reboot-required ]]; then
  echo "REBOOT_REQUIRED=yes"
  cat /var/run/reboot-required.pkgs 2>/dev/null || true
else
  echo "REBOOT_REQUIRED=no"
fi
