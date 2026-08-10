#!/usr/bin/env bash
# List windows (wmctrl). Optional --json.
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
if ! command -v wmctrl >/dev/null 2>&1; then
  echo "install wmctrl" >&2
  exit 1
fi
if [[ "${1:-}" == "--json" ]]; then
  wmctrl -l | python3 -c '
import sys, json
rows=[]
for line in sys.stdin:
    parts=line.rstrip("\n").split(None, 3)
    if len(parts)>=4:
        rows.append({"id":parts[0],"desktop":parts[1],"host":parts[2],"title":parts[3]})
print(json.dumps({"windows":rows}, indent=2))
'
else
  wmctrl -l
fi
