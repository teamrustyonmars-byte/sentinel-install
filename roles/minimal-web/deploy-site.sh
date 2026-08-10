#!/usr/bin/env bash
# On the web host: rsync a local folder into the site root.
# Usage: deploy-site.sh /path/to/static-site [/var/www/html]
set -euo pipefail
SRC="${1:-}"
DEST="${2:-/var/www/html}"
[[ -n "$SRC" && -d "$SRC" ]] || { echo "usage: $0 /path/to/site [dest]"; exit 2; }
rsync -a --delete "${SRC}/" "${DEST}/"
echo "OK deployed $SRC → $DEST"
