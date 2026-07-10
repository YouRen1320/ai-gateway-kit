# Reviewed upstream artifacts

Review date: 2026-07-10

| Component | Version/tag | Multi-platform digest | Source revision |
|---|---|---|---|
| Sub2API | `0.1.151` | `sha256:2ca591c2af97eb0e2797cfc7fb7bd587194d94cebdac76f73d677eeab1d4d6c8` | `deff3123ded1d14e51df1fd1286e3d43ed9ec9bd` |
| PostgreSQL | `18.4-alpine3.24` | `sha256:9a8afca54e7861fd90fab5fdf4c42477a6b1cb7d293595148e674e0a3181de15` | External official image |
| Redis | `8.8.0-alpine3.23` | `sha256:9d317178eceac8454a2284a9e6df2466b93c745529947f0cd42a0fa9609d7005` | External official image |
| Caddy | `2.11.4-alpine` | `sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648` | External official image |

The human-readable tags identify exact patch and Alpine releases. The multi-platform digest remains authoritative and prevents a tag from changing the artifact selected by Compose.

The Linux/amd64 variants were scanned with Trivy 0.71.2 and the database downloaded on 2026-07-10. See [the security baseline](SECURITY_BASELINE.md) for results, the blocking policy, and the one time-limited exception.

Before updating:

1. Read upstream release notes and license changes.
2. Confirm the image label points to the expected source revision.
3. Resolve the multi-platform digest from the registry.
4. Create and verify a backup.
5. Use `./bin/upgrade` for Sub2API application updates.
6. Test restore and rollback against representative data before changing database major versions.
