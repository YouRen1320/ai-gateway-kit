#!/usr/bin/env bash

set -Eeuo pipefail

[[ "${AI_GATEWAY_SMOKE:-}" == "1" ]] || {
  echo "Refusing to pull images or start containers without AI_GATEWAY_SMOKE=1" >&2
  exit 1
}

for cmd in docker curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "Docker daemon is not reachable" >&2; exit 1; }

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-gateway-smoke.XXXXXX")"
RECOVERY_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-gateway-recovery.XXXXXX")"
CLEANUP_IMAGE="$(awk -F= '$1 == "REDIS_IMAGE" { print $2 }' "$SOURCE_ROOT/.env.example")"

make_tree_removable() {
  local directory="$1"
  [[ -d "$directory" ]] || return 0
  if docker image inspect "$CLEANUP_IMAGE" >/dev/null 2>&1; then
    docker run --rm \
      --network none \
      --user 0:0 \
      --entrypoint chmod \
      --volume "$directory:/cleanup" \
      "$CLEANUP_IMAGE" \
      -R a+rwX /cleanup >/dev/null 2>&1 || true
  fi
  chmod -R u+rwX "$directory" >/dev/null 2>&1 || true
}

cleanup() {
  if [[ -f "$TEMP_ROOT/.env" ]]; then
    docker compose --project-directory "$TEMP_ROOT" --env-file "$TEMP_ROOT/.env" -f "$TEMP_ROOT/compose.yaml" -f "$TEMP_ROOT/compose.proxy.yaml" down -v --remove-orphans >/dev/null 2>&1 || true
  fi
  if [[ -f "$RECOVERY_ROOT/.env" ]]; then
    docker compose --project-directory "$RECOVERY_ROOT" --env-file "$RECOVERY_ROOT/.env" -f "$RECOVERY_ROOT/compose.yaml" -f "$RECOVERY_ROOT/compose.proxy.yaml" down -v --remove-orphans >/dev/null 2>&1 || true
  fi
  make_tree_removable "$TEMP_ROOT"
  make_tree_removable "$RECOVERY_ROOT"
  rm -rf "$TEMP_ROOT" "$RECOVERY_ROOT"
}
trap cleanup EXIT

tar -C "$SOURCE_ROOT" \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='runtime' \
  --exclude='backups' \
  --exclude='.state' \
  -cf - . | tar -C "$TEMP_ROOT" -xf -

project="ai-gateway-smoke-${RANDOM}"
(
  cd "$TEMP_ROOT"
  ./bin/setup --domain localhost --admin-email admin@example.com --project-name "$project"
  # shellcheck source=bin/lib.sh
  source ./bin/lib.sh
  target_image="$(env_value SUB2API_IMAGE)"
  baseline_image="weishaw/sub2api:0.1.149@sha256:2f591cdac4a88b8960ce822fffc1af16b0eb2725a0d7f3a26af897122770be6e"
  replace_env_value SUB2API_IMAGE "$baseline_image"
  replace_env_value SERVER_PORT 18080
  replace_env_value PROXY_HTTP_PORT 18081
  replace_env_value PROXY_HTTPS_PORT 18443

  pulled=false
  for attempt in 1 2 3; do
    if docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml pull; then
      pulled=true
      break
    fi
    echo "Image pull attempt $attempt failed; retrying..." >&2
    sleep $((attempt * 5))
  done
  "$pulled" || { echo "Unable to pull pinned images after three attempts" >&2; exit 1; }

  docker compose --env-file .env -f compose.yaml up -d --pull never
  wait_for_http_health 300
  ./bin/doctor

  ./bin/backup --with-secrets
  archive="$(find backups -maxdepth 1 -type f -name 'ai-gateway-*.tar.gz' -print | sort | tail -1)"
  [[ -n "$archive" ]]
  archive="$TEMP_ROOT/$archive"
  if ./bin/restore --from "$archive" --confirm-destroy-existing --restore-secrets --skip-prebackup; then
    echo "Secret restore unexpectedly accepted a non-empty destination" >&2
    exit 1
  fi
  ./bin/restore --from "$archive" --confirm-destroy-existing --skip-prebackup
  curl --fail --silent --show-error --max-time 10 http://127.0.0.1:18080/health >/dev/null

  ./bin/upgrade --sub2api-image "$target_image"
  [[ "$(env_value SUB2API_IMAGE)" == "$target_image" ]]
  ./bin/rollback
  [[ "$(env_value SUB2API_IMAGE)" == "$baseline_image" ]]

  docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml up -d proxy --pull never
  proxy_ready=false
  for _ in {1..40}; do
    if curl --insecure --fail --silent --show-error --max-time 5 https://localhost:18443/health >/dev/null 2>&1; then
      proxy_ready=true
      break
    fi
    sleep 2
  done
  "$proxy_ready" || { docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml logs proxy; exit 1; }

  tar -C "$SOURCE_ROOT" \
    --exclude='.git' \
    --exclude='.env' \
    --exclude='runtime' \
    --exclude='backups' \
    --exclude='.state' \
    -cf - . | tar -C "$RECOVERY_ROOT" -xf -

  docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml down -v --remove-orphans
  (
    cd "$RECOVERY_ROOT"
    ./bin/restore --from "$archive" --confirm-destroy-existing --restore-secrets --skip-prebackup
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:18080/health >/dev/null
    docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml down -v --remove-orphans
  )
)

echo "Runtime smoke, HTTPS proxy, backup, in-place and clean disaster recovery, upgrade, and rollback checks passed."
