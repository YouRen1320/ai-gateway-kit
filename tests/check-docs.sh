#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for file in README.md README.zh-CN.md LICENSE NOTICE SECURITY.md SUPPORT.md CONTRIBUTING.md CODE_OF_CONDUCT.md CHANGELOG.md THIRD_PARTY_NOTICES.md VERSION; do
  [[ -s "$file" ]] || { echo "Required project file is missing or empty: $file" >&2; exit 1; }
done

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "VERSION is not semantic: $version" >&2; exit 1; }
rg -q "^## \[$version\]" CHANGELOG.md || { echo "CHANGELOG has no release heading for $version" >&2; exit 1; }

for key in SUB2API_IMAGE POSTGRES_IMAGE REDIS_IMAGE CADDY_IMAGE; do
  value="$(awk -v wanted="$key" 'index($0, wanted "=") == 1 { sub(/^[^=]*=/, ""); print; exit }' .env.example)"
  image="${value%@sha256:*}"
  digest="sha256:${value##*@sha256:}"
  rg -Fq -- "Reviewed image: \`$image\`" THIRD_PARTY_NOTICES.md || {
    echo "THIRD_PARTY_NOTICES.md is stale for $key" >&2
    exit 1
  }
  rg -Fq -- "$digest" docs/UPSTREAM.md || {
    echo "docs/UPSTREAM.md is stale for $key" >&2
    exit 1
  }
done

failures=0
while IFS=: read -r file line match; do
  target="${match#](}"
  target="${target%)}"
  case "$target" in
    http://*|https://*|mailto:*|\#*) continue ;;
  esac
  path="${target%%#*}"
  [[ -n "$path" ]] || continue
  if [[ ! -e "$(dirname "$file")/$path" ]]; then
    echo "Broken local Markdown link: $file:$line -> $target" >&2
    failures=$((failures + 1))
  fi
done < <(rg -n -o --glob '*.md' '\]\([^)]+\)' .)

((failures == 0)) || exit 1
echo "Documentation structure and local links passed."
