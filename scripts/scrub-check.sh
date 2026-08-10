#!/usr/bin/env bash
# Fail if the tree looks like it has private house inventory or secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
echo "scrub-check: $ROOT"

# Must not ship real secrets files in a publish tree
if [[ -f configs/secrets.env ]]; then
  echo "WARN: configs/secrets.env present locally (gitignored — do not force-add)"
else
  echo "OK: no configs/secrets.env"
fi

# Dangerous secret patterns (not placeholders).
# Build regex in pieces so this script does not self-match.
_pat1='ghp_''[A-Za-z0-9]{20,}'
_pat2='github_pat_''[A-Za-z0-9_]{20,}'
_pat3='sk-''[A-Za-z0-9]{20,}'
_pat4='CF_API_TOKEN=.+'
_pat5='sudo_password[[:space:]]*[:=]'
_pat6='SSH_PASS=.+'
_PAT="${_pat1}|${_pat2}|${_pat3}|${_pat4}|${_pat5}|${_pat6}"
# Exclude self + .git (false positives from the checker source)
_hits="$(grep -RInE --exclude-dir=.git --exclude='scrub-check.sh' "$_PAT" . 2>/dev/null | head -20 || true)"
if [[ -n "$_hits" ]]; then
  echo "$_hits"
  echo "FAIL: token/password-like strings" >&2
  fail=1
else
  echo "OK: no token/password-like strings"
fi
unset _pat1 _pat2 _pat3 _pat4 _pat5 _pat6 _PAT _hits

# Discourage shipping a filled nodes.yaml (committed)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch configs/nodes.yaml >/dev/null 2>&1; then
    echo "FAIL: configs/nodes.yaml is tracked by git (should be gitignored)" >&2
    fail=1
  else
    echo "OK: configs/nodes.yaml not tracked"
  fi
else
  echo "OK: not a git repo (skip track check)"
fi

if [[ $fail -ne 0 ]]; then
  echo "scrub-check FAILED" >&2
  exit 1
fi
echo "scrub-check PASSED"
