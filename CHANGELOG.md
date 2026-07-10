# Changelog

All notable changes are documented here. The project follows semantic versioning after the first public release.

## [Unreleased]

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
