#!/usr/bin/env bash

# Shared helpers intentionally parse .env as data instead of sourcing it as shell code.
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
ok() { printf '[OK] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_env_file() {
  [[ -f "$ENV_FILE" ]] || die "Missing $ENV_FILE. Run ./bin/setup first."
}

env_value_from() {
  local file="$1" key="$2"
  awk -v wanted="$key" '
    index($0, wanted "=") == 1 {
      sub(/^[^=]*=/, "")
      print
      exit
    }
  ' "$file"
}

env_value() {
  env_value_from "$ENV_FILE" "$1"
}

replace_env_value() {
  local key="$1" value="$2" file="${3:-$ENV_FILE}" tmp
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  awk -v wanted="$key" -v replacement="$value" '
    BEGIN { replaced = 0 }
    index($0, wanted "=") == 1 {
      print wanted "=" replacement
      replaced = 1
      next
    }
    { print }
    END {
      if (!replaced) print wanted "=" replacement
    }
  ' "$file" > "$tmp"
  chmod --reference="$file" "$tmp" 2>/dev/null || chmod 600 "$tmp"
  mv "$tmp" "$file"
}

compose() {
  require_env_file
  docker compose \
    --project-directory "$ROOT_DIR" \
    --env-file "$ENV_FILE" \
    -f "$ROOT_DIR/compose.yaml" \
    "$@"
}

compose_with_proxy() {
  require_env_file
  docker compose \
    --project-directory "$ROOT_DIR" \
    --env-file "$ENV_FILE" \
    -f "$ROOT_DIR/compose.yaml" \
    -f "$ROOT_DIR/compose.proxy.yaml" \
    "$@"
}

compose_pull_with_retry() {
  local attempt
  for attempt in 1 2 3; do
    if compose pull "$@"; then
      return 0
    fi
    warn "Image pull attempt $attempt failed; retrying..."
    sleep $((attempt * 5))
  done
  return 1
}

validate_identifier() {
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Unsafe database identifier: $1"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1"
  else
    shasum -a 256 "$1"
  fi
}

verify_sha256_manifest() {
  local manifest="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$(dirname "$manifest")" && sha256sum -c "$(basename "$manifest")")
  else
    (cd "$(dirname "$manifest")" && shasum -a 256 -c "$(basename "$manifest")")
  fi
}

tar_member_is_safe() {
  local clean="${1#./}"
  case "$clean" in
    "") return 0 ;;
    /*|../*|*/../*|*/..) return 1 ;;
    *) return 0 ;;
  esac
}

validate_tar_safety() {
  local archive="$1" member
  tar -tzf "$archive" >/dev/null || return 1

  while IFS= read -r member; do
    tar_member_is_safe "$member" || return 1
  done < <(tar -tzf "$archive")

  # Backup archives are data snapshots; links are unnecessary and can redirect extraction.
  if tar -tvzf "$archive" | awk '$1 ~ /^[lh]/ { found = 1 } END { exit found ? 0 : 1 }'; then
    return 1
  fi
}

archive_runtime_files() {
  local destination="$1" helper_image
  helper_image="$(env_value REDIS_IMAGE)"

  # Container-created state can be unreadable to an unprivileged Linux host user.
  # Reuse the already pinned Redis image as a network-isolated filesystem helper.
  docker run --rm \
    --network none \
    --user 0:0 \
    --entrypoint tar \
    --volume "$ROOT_DIR/runtime/app:/snapshot/runtime/app:ro" \
    --volume "$ROOT_DIR/runtime/redis:/snapshot/runtime/redis:ro" \
    "$helper_image" \
    -C /snapshot \
    --exclude=runtime/app/logs \
    -czf - \
    runtime/app runtime/redis > "$destination"
}

restore_runtime_files() {
  local archive="$1" helper_image
  helper_image="$(env_value REDIS_IMAGE)"

  docker run --rm \
    --network none \
    --user 0:0 \
    --interactive \
    --entrypoint tar \
    --volume "$ROOT_DIR/runtime/app:/restore/runtime/app" \
    --volume "$ROOT_DIR/runtime/redis:/restore/runtime/redis" \
    "$helper_image" \
    -C /restore \
    -xzf - < "$archive"
}

wait_for_http_health() {
  local timeout="${1:-180}" host port url started
  host="$(env_value BIND_HOST)"
  port="$(env_value SERVER_PORT)"
  [[ "$host" == "0.0.0.0" ]] && host="127.0.0.1"
  [[ "$host" == "::" ]] && host="::1"
  url="http://${host}:${port}/health"
  started=$SECONDS

  while (( SECONDS - started < timeout )); do
    if curl --fail --silent --show-error --max-time 5 "$url" >/dev/null 2>&1; then
      ok "Gateway health check passed: $url"
      return 0
    fi
    sleep 3
  done
  warn "Gateway did not become healthy within ${timeout}s: $url"
  return 1
}
