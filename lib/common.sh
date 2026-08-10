#!/usr/bin/env bash
# Shared helpers for sentinel-install (no hard-coded house IPs or passwords).
set -euo pipefail

SI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODES_FILE="${SI_NODES:-$SI_ROOT/configs/nodes.yaml}"
SECRETS_FILE="${SI_SECRETS:-$SI_ROOT/configs/secrets.env}"

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "→ $*"; }
ok() { echo "OK  $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

load_secrets() {
  if [[ -f "$SECRETS_FILE" ]]; then
    # shellcheck disable=SC1090
    set -a
    # shellcheck disable=SC1090
    source "$SECRETS_FILE"
    set +a
  fi
}

# Very small YAML reader for keys we need (no yq required).
# Usage: yaml_get nodes.web.host
yaml_get() {
  local path="$1"
  python3 - "$NODES_FILE" "$path" <<'PY'
import sys, re
path = sys.argv[2].split(".")
text = open(sys.argv[1], encoding="utf-8").read().splitlines()
# strip comments
lines = []
for ln in text:
    if "#" in ln:
        ln = ln[: ln.index("#")]
    lines.append(ln.rstrip())
# naive indent stack
stack = {}
cur = {}
root = cur
indent_stack = [-1]
obj_stack = [cur]
key_path = []

def indent_of(s):
    return len(s) - len(s.lstrip(" "))

# simpler: regex walk for our shallow schema
data = {}
section = None
sub = None
fleet_hosts = []
i = 0
while i < len(lines):
    ln = lines[i]
    if not ln.strip():
        i += 1
        continue
    ind = indent_of(ln)
    s = ln.strip()
    if ind == 0 and s.endswith(":") and not s.startswith("-"):
        section = s[:-1]
        data.setdefault(section, {})
        sub = None
        i += 1
        continue
    if section == "nodes" and ind == 2 and s.endswith(":") and not s.startswith("-"):
        sub = s[:-1]
        data["nodes"][sub] = {}
        i += 1
        continue
    if section == "nodes" and sub and ind >= 4 and ":" in s and not s.startswith("-"):
        k, v = s.split(":", 1)
        v = v.strip().strip('"').strip("'")
        if k.strip() == "paths":
            data["nodes"][sub].setdefault("paths", {})
            i += 1
            while i < len(lines) and indent_of(lines[i]) > ind:
                ps = lines[i].strip()
                if ps and ":" in ps and not ps.startswith("#"):
                    pk, pv = ps.split(":", 1)
                    data["nodes"][sub]["paths"][pk.strip()] = pv.strip().strip('"').strip("'")
                i += 1
            continue
        data["nodes"][sub][k.strip()] = v
        i += 1
        continue
    if section == "fleet" and s.startswith("-"):
        # collect host/user blocks
        host = user = None
        i += 1
        while i < len(lines) and indent_of(lines[i]) >= 4:
            ps = lines[i].strip()
            if ps.startswith("host:"):
                host = ps.split(":",1)[1].strip().strip('"').strip("'")
            if ps.startswith("user:"):
                user = ps.split(":",1)[1].strip().strip('"').strip("'")
            i += 1
        if host:
            fleet_hosts.append({"host": host, "user": user or ""})
        continue
    if ind == 0 and ":" in s and not s.endswith(":"):
        k, v = s.split(":", 1)
        data[k.strip()] = v.strip().strip('"').strip("'")
    i += 1
data["fleet_hosts"] = fleet_hosts

# resolve path
cur = data
for p in path:
    if p == "fleet" and "hosts" in path:
        pass
    if isinstance(cur, dict) and p in cur:
        cur = cur[p]
    elif path == ["fleet", "hosts"]:
        cur = data.get("fleet_hosts", [])
        break
    else:
        # special fleet.hosts
        if path[:2] == ["fleet", "hosts"]:
            cur = data.get("fleet_hosts", [])
            break
        cur = ""
        break
if isinstance(cur, (dict, list)):
    import json
    print(json.dumps(cur))
else:
    print(cur if cur is not None else "")
PY
}

require_nodes() {
  [[ -f "$NODES_FILE" ]] || die "missing $NODES_FILE — copy configs/nodes.example.yaml to configs/nodes.yaml"
  # refuse example placeholders if still default and STRICT
  if grep -q 'CHANGE ME' "$NODES_FILE" 2>/dev/null; then
    info "WARNING: nodes.yaml still contains 'CHANGE ME' placeholders — edit before production use"
  fi
}

ssh_cmd() {
  # ssh_cmd user host remote-command...
  local user="$1" host="$2"
  shift 2
  if [[ -n "${SSH_PASS:-}" ]] && command -v sshpass >/dev/null 2>&1; then
    SSHPASS="$SSH_PASS" sshpass -e ssh -o StrictHostKeyChecking=accept-new "${user}@${host}" "$@"
  else
    ssh -o StrictHostKeyChecking=accept-new "${user}@${host}" "$@"
  fi
}

scp_cmd() {
  local user="$1" host="$2" src="$3" dest="$4"
  if [[ -n "${SSH_PASS:-}" ]] && command -v sshpass >/dev/null 2>&1; then
    SSHPASS="$SSH_PASS" sshpass -e scp -o StrictHostKeyChecking=accept-new "$src" "${user}@${host}:${dest}"
  else
    scp -o StrictHostKeyChecking=accept-new "$src" "${user}@${host}:${dest}"
  fi
}
