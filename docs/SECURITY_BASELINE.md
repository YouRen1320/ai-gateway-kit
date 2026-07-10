# Container vulnerability baseline

Review date: 2026-07-10

This document records scanner evidence, not a claim that the images are vulnerability-free. Container images are third-party artifacts. The kit pins reviewed artifacts, detects regressions, and documents unresolved upstream risk; it does not rebuild or silently patch upstream binaries.

## Policy

- Scan all pinned images for fixable `HIGH` and `CRITICAL` findings before release and weekly after publication.
- Fail the automated scan on any unacknowledged fixable critical finding.
- Keep high findings visible for maintainer review instead of hiding them in a broad allowlist.
- Limit exceptions to a specific finding and path, state the applicability rationale, assign an expiration date, and remove the exception as soon as upstream publishes a corrected artifact.
- Rescan the actual architecture used for production. The recorded baseline below is Linux/amd64; the runtime smoke test separately exercises Linux/arm64 images.

## Recorded results

Trivy 0.71.2 scanned the pinned Linux/amd64 artifacts with the vulnerability database downloaded on 2026-07-10. Only findings with an available fix were counted.

| Image | Critical | High | Disposition |
|---|---:|---:|---|
| Sub2API 0.1.151 | 0 | 10 | Upstream Go dependencies; monitor for a rebuilt release. |
| PostgreSQL 18.4 Alpine 3.24 | 1 | 14 | One narrowly acknowledged `gosu` finding; remaining highs stay visible. |
| Redis 8.8.0 Alpine 3.23 | 0 | 0 | No fixable high or critical findings detected. |
| Caddy 2.11.4 Alpine | 0 | 3 | Upstream Go standard library and Alpine `c-ares`; monitor for a rebuilt release. |

The Sub2API findings are in OpenTelemetry and `golang.org/x/crypto/ssh`. Whether every SSH code path is enabled in a particular deployment was not established, so these findings are not suppressed. The Caddy findings are in its Go standard library and the Alpine `c-ares` package. The PostgreSQL high findings are primarily reported against the bundled `gosu` helper. Consult the current scan output for exact IDs because vulnerability databases and severity ratings change over time.

## Time-limited exception

`CVE-2025-68121` is reported against `usr/local/bin/gosu` in the official PostgreSQL image because the helper was compiled with an affected Go standard-library version. The vulnerable function concerns TLS session resumption. In this image, `gosu` is used only for local user switching during container startup and does not perform network or TLS operations. The exception is path-scoped in `.trivyignore.yaml` and expires on 2026-10-10. This is an applicability judgment, not proof that the official image is generally unaffected.

If a corrected PostgreSQL image appears, update the digest and delete the exception immediately. If the exception expires first, the scheduled workflow must fail until a maintainer re-evaluates the evidence; do not extend it automatically.

## Reproduce

The scan is opt-in because it performs network downloads:

```bash
AI_GATEWAY_IMAGE_SCAN=1 ./tests/scan-images.sh
```

The script uses a digest-pinned Trivy 0.71.2 container when no local `trivy` executable exists. It reports each image's remaining high and critical count and exits non-zero if an unacknowledged critical finding remains.
