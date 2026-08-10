#!/usr/bin/env bash
# Profile: ai-desk — Ollama + companion shell + HouseCap + desk tools (one GPU PC)
# Scrubbed: no house IPs/passwords; reads nodes.yaml
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"
load_secrets
require_nodes
need_cmd ssh

AI_HOST="$(yaml_get nodes.ai.host)"
AI_USER="$(yaml_get nodes.ai.user)"
USE_GPU="$(yaml_get nodes.ai.use_gpu)"
COMPANION_PORT="$(yaml_get nodes.ai.companion_port)"
OLLAMA_PORT="$(yaml_get nodes.ai.ollama_port)"
WEBUI_PORT="$(yaml_get nodes.ai.open_webui_port)"
DESK_HOST="$(yaml_get nodes.desk.host)"
DESK_USER="$(yaml_get nodes.desk.user)"
DISPLAY_V="$(yaml_get nodes.desk.display)"
COMPANION_PORT="${COMPANION_PORT:-8083}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
WEBUI_PORT="${WEBUI_PORT:-8080}"
DISPLAY_V="${DISPLAY_V:-:0}"
[[ -n "$AI_HOST" && -n "$AI_USER" ]] || die "nodes.ai.host and nodes.ai.user required"

info "ai-desk → ${AI_USER}@${AI_HOST} gpu=${USE_GPU:-false}"

# --- Ollama + Open WebUI via compose ---
COMPOSE_SRC="$SI_ROOT/roles/ai-desk/docker-compose.ai-desk.yml"
scp_cmd "$AI_USER" "$AI_HOST" "$COMPOSE_SRC" "/tmp/docker-compose.ai-desk.yml"

ssh_cmd "$AI_USER" "$AI_HOST" bash -s <<REMOTE
set -euo pipefail
mkdir -p "\$HOME/sentinel-ai-desk" "\$HOME/sentinel-ai-desk/data/ollama" "\$HOME/sentinel-ai-desk/data/open-webui"
cp /tmp/docker-compose.ai-desk.yml "\$HOME/sentinel-ai-desk/docker-compose.yml"
cd "\$HOME/sentinel-ai-desk"
# Prefer docker compose plugin
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "Install Docker + compose plugin first." >&2
  exit 1
fi
export OLLAMA_PORT="${OLLAMA_PORT}"
export WEBUI_PORT="${WEBUI_PORT}"
export USE_GPU="${USE_GPU:-false}"
\$DC pull || true
\$DC up -d
echo "Ollama :${OLLAMA_PORT}  Open WebUI :${WEBUI_PORT}"
REMOTE

# --- Companion stub (static note + optional container later) ---
scp_cmd "$AI_USER" "$AI_HOST" \
  "$SI_ROOT/roles/ai-desk/companion-README.md" \
  "\$HOME/sentinel-ai-desk/COMPANION.md" 2>/dev/null || \
ssh_cmd "$AI_USER" "$AI_HOST" "mkdir -p \$HOME/sentinel-ai-desk" 
scp_cmd "$AI_USER" "$AI_HOST" \
  "$SI_ROOT/roles/ai-desk/companion-README.md" \
  "/tmp/COMPANION.md"
ssh_cmd "$AI_USER" "$AI_HOST" "mv /tmp/COMPANION.md \$HOME/sentinel-ai-desk/COMPANION.md"

# --- HouseCap (free Linux recorder) ---
if [[ -d /home/sentinel/ai-share/housecap ]]; then
  info "syncing HouseCap sources"
  rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" \
    --exclude .git \
    /home/sentinel/ai-share/housecap/ \
    "${AI_USER}@${AI_HOST}:/tmp/housecap/"
  ssh_cmd "$AI_USER" "$AI_HOST" bash -s <<'REMOTE'
set -euo pipefail
mkdir -p "$HOME/src" "$HOME/.local/bin"
rm -rf "$HOME/src/housecap"
mv /tmp/housecap "$HOME/src/housecap"
bash "$HOME/src/housecap/install.sh"
REMOTE
  ok "HouseCap on AI host"
else
  info "HouseCap not on this machine — on target: git clone https://github.com/teamrustyonmars-byte/housecap.git && ./install.sh"
  ssh_cmd "$AI_USER" "$AI_HOST" bash -s <<'REMOTE'
set -euo pipefail
if [[ ! -x "$HOME/.local/bin/housecap" ]]; then
  mkdir -p "$HOME/src" && cd "$HOME/src"
  if [[ ! -d housecap ]]; then
    git clone --depth 1 https://github.com/teamrustyonmars-byte/housecap.git || true
  fi
  if [[ -d housecap ]]; then
    bash housecap/install.sh || true
  fi
fi
REMOTE
fi

# --- Desk tools (on desk host; may equal AI host) ---
DESK_HOST="${DESK_HOST:-$AI_HOST}"
DESK_USER="${DESK_USER:-$AI_USER}"
info "desk tools → ${DESK_USER}@${DESK_HOST}"
rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" \
  "$SI_ROOT/roles/ai-desk/desk-tools/" \
  "${DESK_USER}@${DESK_HOST}:/tmp/desk-tools/"
ssh_cmd "$DESK_USER" "$DESK_HOST" bash -s <<REMOTE
set -euo pipefail
mkdir -p "\$HOME/.local/bin" "\$HOME/.local/share/desk-tools"
cp -a /tmp/desk-tools/. "\$HOME/.local/share/desk-tools/"
ln -sfn "\$HOME/.local/share/desk-tools/desk-shot.sh" "\$HOME/.local/bin/desk-shot"
ln -sfn "\$HOME/.local/share/desk-tools/desk-windows.sh" "\$HOME/.local/bin/desk-windows"
ln -sfn "\$HOME/.local/share/desk-tools/audio-default-analog.sh" "\$HOME/.local/bin/audio-default-analog"
chmod +x "\$HOME/.local/share/desk-tools/"*.sh
# optional packages (best effort, no password prompt if sudo -n fails)
sudo -n apt-get install -y xdotool wmctrl scrot 2>/dev/null || true
echo "DISPLAY preferred: ${DISPLAY_V}"
REMOTE

ok "ai-desk role applied"
info "Ollama:    http://${AI_HOST}:${OLLAMA_PORT}"
info "Open WebUI: http://${AI_HOST}:${WEBUI_PORT}"
info "HouseCap:  housecap doctor --json (on AI/desk host)"
info "Companion: see ~/sentinel-ai-desk/COMPANION.md — wire your own image/port ${COMPANION_PORT}"
