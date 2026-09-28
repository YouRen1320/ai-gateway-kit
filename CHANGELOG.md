# Changelog

All notable changes are documented here. The project follows semantic versioning after the first public release.

## [Unreleased]

### Changed

- 模板固定镜像升级为 Sub2API 0.2.9（多平台摘要 `sha256:1f4a15d2…`），依据 2026-09-28 的同日扫描（High 45→4）、77 个新增 SQL 迁移审阅与隔离栈升级/回滚演练；演练证据与回滚顺序要点见升级说明。

## [0.1.0] - 2026-07-10

### Added

- Brand-neutral Sub2API, PostgreSQL, and Redis deployment stack.
- Optional Caddy automatic HTTPS edge.
- Secure one-time setup with generated secrets.
- Static and runtime diagnostics.
- Logical backup, explicit restore, controlled application upgrade, and image rollback workflows.
- Architecture, configuration, operations, rebranding, compliance, security, and contribution documentation.
- CI validation, scheduled container vulnerability scanning, and an opt-in runtime smoke test.

### Security

- Loopback-only application binding by default.
- Private backend network for PostgreSQL and Redis.
- Required Redis authentication.
- Plaintext and private-host upstream URLs disabled by default.
- Immutable image digests.
- Latest reviewed patch-level image tags and an expiring, documented exception for one non-reachable scanner finding.
- Runtime data, secrets, logs, and backups excluded from Git.
