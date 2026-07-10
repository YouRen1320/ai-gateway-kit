#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for cmd in awk docker rg sed sort; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done
docker compose version >/dev/null

echo "Checking shell syntax..."
while IFS= read -r file; do
  bash -n "$file"
done < <(find bin tests -type f -not -name '*.md' -print | sort)

echo "Checking executable permissions..."
while IFS= read -r file; do
  [[ -x "$file" ]] || { echo "Not executable: $file" >&2; exit 1; }
done < <(find bin tests -type f -not -name '*.md' -print | sort)

tmp_env="$(mktemp "${TMPDIR:-/tmp}/ai-gateway-env.XXXXXX")"
trap 'rm -f "$tmp_env"' EXIT
cp .env.example "$tmp_env"
for key in POSTGRES_PASSWORD REDIS_PASSWORD ADMIN_PASSWORD JWT_SECRET TOTP_ENCRYPTION_KEY; do
  awk -v wanted="$key" '
    index($0, wanted "=") == 1 { print wanted "=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"; next }
    { print }
  ' "$tmp_env" > "${tmp_env}.next"
  mv "${tmp_env}.next" "$tmp_env"
done

echo "Validating Compose models..."
docker compose --project-directory "$ROOT_DIR" --env-file "$tmp_env" -f compose.yaml config --quiet
docker compose --project-directory "$ROOT_DIR" --env-file "$tmp_env" -f compose.yaml -f compose.proxy.yaml config --quiet

echo "Checking image pins..."
for key in SUB2API_IMAGE POSTGRES_IMAGE REDIS_IMAGE CADDY_IMAGE; do
  value="$(awk -v wanted="$key" 'index($0, wanted "=") == 1 { sub(/^[^=]*=/, ""); print; exit }' .env.example)"
  [[ "$value" =~ @sha256:[0-9a-f]{64}$ ]] || { echo "$key is not digest-pinned" >&2; exit 1; }
done

echo "Checking configuration contract..."
awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' .env.example | sort -u > "${tmp_env}.keys"
{
  rg -o '\$\{[A-Za-z_][A-Za-z0-9_]*' compose.yaml compose.proxy.yaml | sed -E 's/.*\$\{//'
  rg -o '\{\$[A-Za-z_][A-Za-z0-9_]*' config/Caddyfile | sed -E 's/.*\{\$//'
} | sort -u > "${tmp_env}.refs"

missing="$(comm -13 "${tmp_env}.keys" "${tmp_env}.refs" || true)"
[[ -z "$missing" ]] || { echo "Compose/Caddy variables missing from .env.example:" >&2; echo "$missing" >&2; exit 1; }

# COMPOSE_PROJECT_NAME is consumed by Compose itself; every other example key must be referenced.
unused="$(comm -23 "${tmp_env}.keys" "${tmp_env}.refs" | rg -v '^COMPOSE_PROJECT_NAME$' || true)"
[[ -z "$unused" ]] || { echo "Unused .env.example variables:" >&2; echo "$unused" >&2; exit 1; }

[[ "$(awk -F= '$1 == "SECURITY_URL_ALLOWLIST_ENABLED" { print $2 }' .env.example)" == "true" ]] || {
  echo "SECURITY_URL_ALLOWLIST_ENABLED must default to true" >&2
  exit 1
}
for key in SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS; do
  [[ "$(awk -F= -v wanted="$key" '$1 == wanted { print $2 }' .env.example)" == "false" ]] || {
    echo "$key must default to false" >&2
    exit 1
  }
done
[[ -n "$(awk -F= '$1 == "SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS" { print $2 }' .env.example)" ]] || {
  echo "SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS must not be empty" >&2
  exit 1
}

rm -f "${tmp_env}.keys" "${tmp_env}.refs"

echo "Checking repository for secrets and production artifacts..."
./tests/check-secrets.sh

echo "Checking project documentation and release metadata..."
./tests/check-docs.sh

echo "Checking backup archive safety rules..."
./tests/archive-safety.sh

echo "All static validation checks passed."
