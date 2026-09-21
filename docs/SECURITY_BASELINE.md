# Container vulnerability baseline

## 2026-09-20 复核结果

本次更新 PostgreSQL 18.6、Redis 8.8.2 和 Caddy 2.11.4 的重建镜像，固定摘要见 `.env.example`。Sub2API 保留 0.1.151，跨到 0.2 系列需要单独评估数据迁移和回滚。以下为同日 Linux/amd64、Trivy 0.71.2、仅统计有修复版本、应用现有路径级例外后的结果；不代表没有漏洞。

| 镜像 | 更新前 Critical / High | 更新后 Critical / High |
|---|---:|---:|
| Sub2API | 0 / 45 | 0 / 45 |
| PostgreSQL | 0 / 31 | 0 / 21 |
| Redis | 0 / 8 | 0 / 0 |
| Caddy | 0 / 40 | 0 / 17 |

- [更新前扫描](https://github.com/YouRen1320/ai-gateway-kit/actions/runs/35513398088)与[更新后扫描](https://github.com/YouRen1320/ai-gateway-kit/actions/runs/35513534387)均已完成。本轮 High 合计从 124 降到 83；Critical 为 0 不是本轮消除历史 Critical 的证据，漏洞库会更新评级。
- [运行、备份恢复、升级及回滚测试](https://github.com/YouRen1320/ai-gateway-kit/actions/runs/35513538876)和[静态检查](https://github.com/YouRen1320/ai-gateway-kit/actions/runs/35513530538)通过。运行测试使用 GitHub 托管 Linux/amd64；本轮未实测 arm64，未部署生产。
- PostgreSQL 剩余 High 位于 `gosu`；Sub2API 和 Caddy 仍含上游库/Go 运行时告警。未新增忽略规则，现有 `gosu` 例外仍于 2026-10-10 到期，需要继续跟踪上游镜像，不能视为风险清零。
- [问题 #4](https://github.com/YouRen1320/ai-gateway-kit/issues/4)继续开放，跟踪剩余风险及 Sub2API 的独立升级评估。下方保留旧基线作为历史证据，不应当作当前结果。

## 历史基线（2026-07-10）

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
