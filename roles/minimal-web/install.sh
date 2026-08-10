#!/usr/bin/env bash
# Profile: minimal-web — Apache + dashboard shell + deploy script (site only)
# Scrubbed template: uses nodes.yaml only (no hard-coded IPs/passwords).
set -euo pipefail
SI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$SI_ROOT/lib/common.sh"
load_secrets
require_nodes
need_cmd ssh
need_cmd scp

WEB_HOST="$(yaml_get nodes.web.host)"
WEB_USER="$(yaml_get nodes.web.user)"
SITE_ROOT="$(yaml_get nodes.web.paths.site_root)"
DEPLOY_SRC="$(yaml_get nodes.web.paths.deploy_src)"
[[ -n "$WEB_HOST" && -n "$WEB_USER" ]] || die "nodes.web.host and nodes.web.user required"
SITE_ROOT="${SITE_ROOT:-/var/www/html}"

info "minimal-web → ${WEB_USER}@${WEB_HOST} site_root=${SITE_ROOT}"

# 1) Ensure Apache on target (user must have sudo; key-based sudo -n preferred)
ssh_cmd "$WEB_USER" "$WEB_HOST" bash -s <<REMOTE
set -euo pipefail
if ! command -v apache2 >/dev/null 2>&1 && ! command -v httpd >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo -n apt-get update -qq
    sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
  else
    echo "Install Apache manually, then re-run." >&2
    exit 1
  fi
fi
sudo -n mkdir -p "$SITE_ROOT"
sudo -n chown -R "\$USER:\$USER" "$SITE_ROOT" 2>/dev/null || true
REMOTE

# 2) Dashboard shell payload
PAYLOAD="$SI_ROOT/payloads/web-dashboard-shell"
[[ -d "$PAYLOAD" ]] || die "missing payload $PAYLOAD"
info "deploying dashboard shell"
rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" \
  "$PAYLOAD/" "${WEB_USER}@${WEB_HOST}:${SITE_ROOT}/"

# 3) Optional site content
if [[ -n "$DEPLOY_SRC" && -d "$SI_ROOT/$DEPLOY_SRC" ]]; then
  info "deploying site content from $DEPLOY_SRC"
  rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" \
    "$SI_ROOT/$DEPLOY_SRC/" "${WEB_USER}@${WEB_HOST}:${SITE_ROOT}/"
elif [[ -n "$DEPLOY_SRC" && -d "$DEPLOY_SRC" ]]; then
  rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" \
    "$DEPLOY_SRC/" "${WEB_USER}@${WEB_HOST}:${SITE_ROOT}/"
else
  info "no extra site content (add payloads/web-site or set deploy_src)"
fi

# 4) Install deploy helper on target
scp_cmd "$WEB_USER" "$WEB_HOST" \
  "$SI_ROOT/roles/minimal-web/deploy-site.sh" \
  "/tmp/deploy-site.sh"
ssh_cmd "$WEB_USER" "$WEB_HOST" \
  "install -m 755 /tmp/deploy-site.sh \$HOME/bin/deploy-site.sh 2>/dev/null || \
   (mkdir -p \$HOME/bin && install -m 755 /tmp/deploy-site.sh \$HOME/bin/deploy-site.sh)"

ok "minimal-web installed on ${WEB_HOST}"
info "Open: http://${WEB_HOST}/  and  http://${WEB_HOST}/dashboard.html"
