#!/usr/bin/env bash
# Profile: homelab-core — Web + AI edge + infra monitor + fleet apt (2–3 boxes)
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"
load_secrets
require_nodes

info "homelab-core = minimal-web + ai-desk + infra-monitor + fleet-apt"

bash "$SI_ROOT/roles/minimal-web/install.sh"
bash "$SI_ROOT/roles/ai-desk/install.sh"
bash "$SI_ROOT/roles/homelab-core/install-infra-monitor.sh"
bash "$SI_ROOT/roles/homelab-core/install-fleet-apt.sh"

ok "homelab-core profile finished"
info "Next: point your dashboard cards at real service URLs; add tunnels if public."
