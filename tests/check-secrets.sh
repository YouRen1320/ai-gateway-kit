#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
require rg

failures=0
fail() { echo "[FAIL] $*" >&2; failures=$((failures + 1)); }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tracked="$(git ls-files)"
  if printf '%s\n' "$tracked" | rg -n '(^|/)(\.env|runtime|backups|\.state|data|logs)(/|$)|\.(key|pem|p12|pfx|crt|dump|sql|sqlite|rdb|aof|zip|tgz)$' >/dev/null; then
    fail "Tracked runtime, secret, key, database, log, or archive file detected"
    printf '%s\n' "$tracked" | rg '(^|/)(\.env|runtime|backups|\.state|data|logs)(/|$)|\.(key|pem|p12|pfx|crt|dump|sql|sqlite|rdb|aof|zip|tgz)$' >&2 || true
  fi
fi

# Split known strings so this scanner does not match its own source code.
blocked_terms=(
  "friend""aix.com"
  "67.216.""194.162"
  "cfut""_"
  "github_pat""_"
  "ghp""_"
  "AKIA""[A-Z0-9]{16}"
)

for term in "${blocked_terms[@]}"; do
  if rg -n --hidden \
    -g '!.git/**' \
    -g '!.env' \
    -g '!runtime/**' \
    -g '!backups/**' \
    -g '!.state/**' \
    -g '!tests/check-secrets.sh' \
    "$term" . >/dev/null; then
    fail "Blocked secret or production-specific pattern detected"
    rg -n --hidden -g '!.git/**' -g '!.env' -g '!runtime/**' -g '!backups/**' -g '!.state/**' -g '!tests/check-secrets.sh' "$term" . >&2 || true
  fi
done

if rg -n --hidden \
  -g '!.git/**' \
  -g '!.env' \
  -g '!runtime/**' \
  -g '!backups/**' \
  -g '!.state/**' \
  -g '!tests/check-secrets.sh' \
  -- "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|https?://[^[:space:]\"]+:[^[:space:]\"]+@" . >/dev/null; then
  fail "Private key material or credential-bearing URL detected"
fi

if ((failures > 0)); then
  echo "Secret scan failed with $failures finding(s)." >&2
  exit 1
fi

echo "Secret scan passed."
