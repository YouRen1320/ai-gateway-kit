# Reviewed upstream artifacts

基础镜像摘要复核日期：2026-09-20。Sub2API 仍使用原版本，迁移另行评估。

| Component | Version/tag | Multi-platform digest | Source revision |
|---|---|---|---|
| Sub2API | `0.1.151` | `sha256:2ca591c2af97eb0e2797cfc7fb7bd587194d94cebdac76f73d677eeab1d4d6c8` | `deff3123ded1d14e51df1fd1286e3d43ed9ec9bd` |
| PostgreSQL | `18.6-alpine3.24` | `sha256:6c538e7206ea40ff740ef27883529390a690b6ead6ba96b44c67a9f7c638e8fd` | 官方多架构镜像 |
| Redis | `8.8.2-alpine3.23` | `sha256:e2c307e77bcaf306fa9e468bda845165a46c4c015ffd238fb3c92ae5d71d486f` | 官方多架构镜像 |
| Caddy | `2.11.4-alpine` | `sha256:de23def33b17fb5d1290b0f6c2add1d70780e52341896c00a4c8a2a2fe9d355e` | 官方同版本重建镜像 |

The human-readable tags identify exact patch and Alpine releases. The multi-platform digest remains authoritative and prevents a tag from changing the artifact selected by Compose.

2026-09-20 已通过 Docker Hub 标签元数据核对上述三项多架构摘要，均包含 Linux/amd64 与 Linux/arm64。扫描结果及仍未解决的问题见[安全基线](SECURITY_BASELINE.md)，升级与回滚注意事项见[升级说明](UPGRADING.md)。

Before updating:

1. Read upstream release notes and license changes.
2. Confirm the image label points to the expected source revision.
3. Resolve the multi-platform digest from the registry.
4. Create and verify a backup.
5. Use `./bin/upgrade` for Sub2API application updates.
6. Test restore and rollback against representative data before changing database major versions.
