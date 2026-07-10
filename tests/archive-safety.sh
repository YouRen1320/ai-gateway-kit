#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=bin/lib.sh
source "$ROOT_DIR/bin/lib.sh"

for member in "" ./ ./database.dump runtime/app/config.yaml runtime/redis/dump.rdb; do
  tar_member_is_safe "$member" || { echo "Safe archive member rejected: $member" >&2; exit 1; }
done

for member in /etc/passwd ../escape ./../escape runtime/../../escape runtime/app/..; do
  if tar_member_is_safe "$member"; then
    echo "Unsafe archive member accepted: $member" >&2
    exit 1
  fi
done

tmp="$(mktemp -d "${TMPDIR:-/tmp}/archive-safety.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
printf 'safe\n' > "$tmp/regular"
tar -C "$tmp" -czf "$tmp/safe.tar.gz" regular
validate_tar_safety "$tmp/safe.tar.gz" || { echo "Safe archive rejected" >&2; exit 1; }

ln -s regular "$tmp/link"
tar -C "$tmp" -czf "$tmp/link.tar.gz" link
if validate_tar_safety "$tmp/link.tar.gz"; then
  echo "Archive containing a symbolic link was accepted" >&2
  exit 1
fi

echo "Archive safety checks passed."
