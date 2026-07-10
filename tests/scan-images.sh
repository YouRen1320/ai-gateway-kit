#!/usr/bin/env bash

set -Eeuo pipefail

[[ "${AI_GATEWAY_IMAGE_SCAN:-}" == "1" ]] || {
  echo "Refusing to download scanner data or images without AI_GATEWAY_IMAGE_SCAN=1" >&2
  exit 1
}

for cmd in id jq mktemp rm; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-gateway-image-scan.XXXXXX")"
CACHE_DIR="$RESULTS_DIR/cache"
mkdir -p "$CACHE_DIR"
trap 'rm -rf "$RESULTS_DIR"' EXIT

# The scanner itself is immutable so the scheduled policy cannot change silently.
TRIVY_IMAGE="aquasec/trivy:0.71.2@sha256:f5d0e600ecda7449e2a9b272805aef698631d3bb3f3a739a750de2c6819acdc9"

run_trivy() {
  if command -v trivy >/dev/null 2>&1; then
    trivy "$@"
    return
  fi

  command -v docker >/dev/null 2>&1 || { echo "Install Trivy or Docker" >&2; return 1; }
  docker info >/dev/null 2>&1 || { echo "Docker daemon is not reachable" >&2; return 1; }
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --env TRIVY_CACHE_DIR=/tmp/trivy-cache \
    --volume "$ROOT_DIR:/workspace:ro" \
    --volume "$CACHE_DIR:/tmp/trivy-cache" \
    --workdir /workspace \
    "$TRIVY_IMAGE" "$@"
}

env_value() {
  local key="$1"
  awk -v wanted="$key" 'index($0, wanted "=") == 1 { sub(/^[^=]*=/, ""); print; exit }' "$ROOT_DIR/.env.example"
}

failed=0
printf '%-18s %8s %8s\n' IMAGE CRITICAL HIGH
for key in SUB2API_IMAGE POSTGRES_IMAGE REDIS_IMAGE CADDY_IMAGE; do
  image="$(env_value "$key")"
  [[ -n "$image" ]] || { echo "Missing $key in .env.example" >&2; exit 1; }
  output="$RESULTS_DIR/$key.json"

  run_trivy image \
    --quiet \
    --scanners vuln \
    --ignore-unfixed \
    --ignorefile .trivyignore.yaml \
    --severity HIGH,CRITICAL \
    --format json \
    "$image" > "$output"

  critical="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$output")"
  high="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$output")"
  printf '%-18s %8d %8d\n' "$key" "$critical" "$high"
  ((critical == 0)) || failed=1
done

echo
printf '%-18s %-8s %-18s %-28s %s\n' IMAGE SEVERITY VULNERABILITY PACKAGE TARGET
for key in SUB2API_IMAGE POSTGRES_IMAGE REDIS_IMAGE CADDY_IMAGE; do
  jq -r '
    .Results[]? as $result
    | $result.Vulnerabilities[]?
    | [.Severity, .VulnerabilityID, .PkgName, $result.Target]
    | @tsv
  ' "$RESULTS_DIR/$key.json" | while IFS=$'\t' read -r severity vulnerability package target; do
    printf '%-18s %-8s %-18s %-28s %s\n' "$key" "$severity" "$vulnerability" "$package" "$target"
  done
done

((failed == 0)) || {
  echo "Unacknowledged fixable critical vulnerabilities detected." >&2
  exit 1
}

echo "No unacknowledged fixable critical vulnerabilities detected. Review all high findings before release."
