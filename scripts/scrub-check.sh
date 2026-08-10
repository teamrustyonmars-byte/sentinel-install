#!/usr/bin/env bash
# Fail if the tree looks like it has private house inventory or secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
check() {
  local label="$1"
  shift
  if rg -n --hidden --glob '!.git/*' "$@" . 2>/dev/null | head -20; then
    echo "FAIL: $label" >&2
    fail=1
  else
    echo "OK: $label"
  fi
}

echo "scrub-check: $ROOT"

# Must not ship real secrets files
if [[ -f configs/secrets.env ]]; then
  echo "FAIL: configs/secrets.env present (gitignored — remove before publish)" >&2
  fail=1
else
  echo "OK: no configs/secrets.env"
fi

# Dangerous secret patterns (not placeholders)
if rg -n --hidden --glob '!.git/*' \
  -e 'ghp_[A-Za-z0-9]{20,}' \
  -e 'github_pat_[A-Za-z0-9_]{20,}' \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e 'CF_API_TOKEN=.+' \
  -e 'sudo_password\s*[:=]' \
  -e 'SSH_PASS=.+' \
  . 2>/dev/null | head -20; then
  echo "FAIL: token/password-like strings" >&2
  fail=1
else
  echo "OK: no token/password-like strings"
fi

# Discourage shipping a filled nodes.yaml with non-example hosts (committed)
if git ls-files --error-unmatch configs/nodes.yaml >/dev/null 2>&1; then
  echo "FAIL: configs/nodes.yaml is tracked by git (should be gitignored)" >&2
  fail=1
else
  echo "OK: configs/nodes.yaml not tracked"
fi

if [[ $fail -ne 0 ]]; then
  echo "scrub-check FAILED" >&2
  exit 1
fi
echo "scrub-check PASSED"
