#!/usr/bin/env bash
# Fleet apt helpers — scrubbed; uses fleet.hosts from nodes.yaml
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"
load_secrets
require_nodes

info "installing fleet-apt scripts on each fleet host"

HOSTS_JSON="$(yaml_get fleet.hosts)"
python3 - "$HOSTS_JSON" "$SI_ROOT" <<'PY' | while IFS=$'\t' read -r user host; do
import json, sys
hosts = json.loads(sys.argv[1] or "[]")
for h in hosts:
    u = h.get("user") or ""
    host = h.get("host") or ""
    if host:
        print(f"{u}\t{host}")
PY
  [[ -n "$host" ]] || continue
  user="${user:-root}"
  info "fleet-apt → ${user}@${host}"
  scp_cmd "$user" "$host" \
    "$SI_ROOT/roles/homelab-core/fleet/fleet-apt-check.sh" \
    "/tmp/fleet-apt-check.sh"
  scp_cmd "$user" "$host" \
    "$SI_ROOT/roles/homelab-core/fleet/fleet-apt-apply.sh" \
    "/tmp/fleet-apt-apply.sh"
  ssh_cmd "$user" "$host" bash -s <<'REMOTE'
set -euo pipefail
mkdir -p "$HOME/bin"
install -m 755 /tmp/fleet-apt-check.sh "$HOME/bin/fleet-apt-check.sh"
install -m 755 /tmp/fleet-apt-apply.sh "$HOME/bin/fleet-apt-apply.sh"
echo "installed ~/bin/fleet-apt-check.sh and fleet-apt-apply.sh"
REMOTE
done

ok "fleet apt helpers installed (run check/apply per host manually or via cron)"
