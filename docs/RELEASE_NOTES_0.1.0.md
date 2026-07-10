# AI Gateway Kit 0.1.0

Initial public-ready release of the brand-neutral deployment core.

## Included

- Digest-pinned Sub2API 0.1.151, PostgreSQL 18.4, Redis 8.8.0, and optional Caddy 2.11.4.
- Loopback-only direct application access and an internal database/cache network.
- Enabled upstream hostname allowlisting and resolved-IP SSRF checks with HTTPS-only, public-address defaults.
- Secure one-time initialization without printing generated credentials.
- Bilingual quick starts and detailed architecture, configuration, operations, rebranding, compliance, security, and release documentation.
- Diagnosis, logical backup, guarded restore, controlled Sub2API upgrade, and image rollback commands.
- Static configuration, documentation, archive-safety, secret, ShellCheck, Gitleaks, and scheduled container-vulnerability checks.
- Opt-in isolated runtime test covering initialization, health, HTTPS proxying, backup, restore, upgrade, and rollback.

## Verified

Local release validation on 2026-07-10 used:

- macOS 26 (`arm64`) host.
- Docker Engine 28.4.0 Linux `arm64` VM.
- Docker Compose 2.39.4.
- Sub2API upgrade path from 0.1.149 to 0.1.151 and image rollback to 0.1.149.

The following passed against a clean temporary copy:

- Secret generation and file permissions.
- Base and proxy Compose model validation.
- PostgreSQL and Redis health checks.
- Sub2API HTTP health endpoint.
- Caddy local HTTPS health endpoint.
- Backup payload checksums.
- Destructive database/runtime restore followed by health verification.
- Refusal to import infrastructure secrets into a non-empty destination.
- Application image upgrade and rollback followed by health verification.
- Cleanup of temporary containers, networks, and volumes.

Trivy 0.71.2 also scanned every pinned Linux/amd64 image for fixable high and critical findings. There were no unacknowledged critical findings after applying the narrow, expiring PostgreSQL `gosu` exception documented in [the security baseline](SECURITY_BASELINE.md). Remaining upstream high findings are recorded there and are not represented as fixed by this kit.

## Migration

This is the first release. It intentionally does not migrate New API/MySQL data, private Sub2API patches, Hermes, Xray/VPN configuration, or production archives. Those are separate systems and must not be copied into the public repository.

## Known boundaries

- Sub2API is third-party software. Its upstream LGPL-3.0 license file and README commercial-authorization statement should be clarified with upstream before commercial reliance.
- This kit does not provide legal authorization to resell model access or share consumer accounts.
- PostgreSQL and Redis major-version upgrades require their own migration and rollback plan.
- Provider configuration and application-level functionality remain the responsibility of Sub2API and the operator.
- The latest reviewed upstream images still contain fixable high-severity scanner findings; consult `docs/SECURITY_BASELINE.md` before production use and rerun the scan at deployment time.

## Rollback

For an application-only failure, run `./bin/rollback`. If a target release changed database state incompatibly, restore the pre-upgrade backup according to `docs/OPERATIONS.md` and `docs/UPGRADING.md`.
