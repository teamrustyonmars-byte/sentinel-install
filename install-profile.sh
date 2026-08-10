#!/usr/bin/env bash
# Install one scrubbed profile: minimal-web | ai-desk | homelab-core
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"

PROFILE="${1:-}"
if [[ -z "$PROFILE" || "$PROFILE" == "-h" || "$PROFILE" == "--help" ]]; then
  cat <<EOF
Usage: $0 <minimal-web|ai-desk|homelab-core>

Setup (once):
  cp configs/nodes.example.yaml configs/nodes.yaml   # edit IPs/users
  cp configs/secrets.example.env configs/secrets.env # chmod 600; optional
  # Prefer SSH keys to all target hosts (sudo -n for remote package installs)

Profiles:
  minimal-web   Apache + dashboard shell + deploy helper (1 web box)
  ai-desk       Ollama + Open WebUI + HouseCap + desk tools (1 GPU/desk PC)
  homelab-core  web + ai-desk + infra monitor + fleet apt (2–3 boxes)

No hard-coded house IPs or sudo passwords in this pack.
EOF
  exit 0
fi

case "$PROFILE" in
  minimal-web)
    bash "$SI_ROOT/roles/minimal-web/install.sh"
    ;;
  ai-desk)
    bash "$SI_ROOT/roles/ai-desk/install.sh"
    ;;
  homelab-core)
    bash "$SI_ROOT/roles/homelab-core/install.sh"
    ;;
  *)
    die "unknown profile: $PROFILE"
    ;;
esac
