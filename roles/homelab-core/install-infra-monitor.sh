#!/usr/bin/env bash
# Lightweight infra monitor (HTTP health JSON) — scrubbed template.
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"
load_secrets
require_nodes
need_cmd ssh

INFRA_HOST="$(yaml_get nodes.infra.host)"
INFRA_USER="$(yaml_get nodes.infra.user)"
MON_PORT="$(yaml_get nodes.infra.monitor_port)"
MON_PORT="${MON_PORT:-8085}"
[[ -n "$INFRA_HOST" && -n "$INFRA_USER" ]] || die "nodes.infra.host and user required"

info "infra-monitor → ${INFRA_USER}@${INFRA_HOST}:${MON_PORT}"

# Build probe list from fleet hosts in nodes.yaml
PROBES_JSON="$(yaml_get fleet.hosts)"
scp_cmd "$INFRA_USER" "$INFRA_HOST" \
  "$SI_ROOT/roles/homelab-core/monitor/simple_monitor.py" \
  "/tmp/simple_monitor.py"
ssh_cmd "$INFRA_USER" "$INFRA_HOST" bash -s <<REMOTE
set -euo pipefail
mkdir -p "\$HOME/sentinel-monitor"
mv /tmp/simple_monitor.py "\$HOME/sentinel-monitor/simple_monitor.py"
chmod +x "\$HOME/sentinel-monitor/simple_monitor.py"
cat > "\$HOME/sentinel-monitor/targets.json" <<'EOF'
${PROBES_JSON}
EOF
# systemd user service
mkdir -p "\$HOME/.config/systemd/user"
cat > "\$HOME/.config/systemd/user/sentinel-monitor.service" <<EOF
[Unit]
Description=Sentinel simple LAN monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 \$HOME/sentinel-monitor/simple_monitor.py --port ${MON_PORT} --targets \$HOME/sentinel-monitor/targets.json
Restart=on-failure

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now sentinel-monitor.service
echo "monitor http://127.0.0.1:${MON_PORT}/health (on infra host)"
REMOTE

ok "infra monitor on ${INFRA_HOST}:${MON_PORT}"
