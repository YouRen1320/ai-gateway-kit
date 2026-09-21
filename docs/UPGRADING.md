# Upgrade and rollback

## 2026-09 基础镜像补丁

默认模板将 PostgreSQL 18.4 更新为 18.6（保持 Alpine 3.24）、Redis 8.8.0 更新为 8.8.2（保持 Alpine 3.23），Caddy 保持 2.11.4 并固定新的官方重建摘要。Sub2API 版本不变。

此变更只更新模板，不改已有部署的 `.env`。既有实例更新前必须备份数据库、Redis 持久化文件和旧镜像引用，并在隔离环境验证备份恢复、管理员登录及数据读取。

PostgreSQL 官方说明 18.x 内更新无需 dump/restore 迁移，但 18.6 涉及逻辑解码插件白名单、pgcrypto 数据处理及部分扩展索引修复。使用自定义逻辑复制插件、GIN、btree_gist 或 ltree 的部署，应逐项检查[18.6 发布说明](https://www.postgresql.org/docs/release/18.6/)；不能仅以健康接口成功作为生产验收。

回滚时先停止应用写入，恢复保存的镜像引用。若涉及数据清理、扩展索引重建或不兼容的持久化文件，使用升级前备份恢复；不要假定只切换旧镜像即可撤销数据变更。此模板更新不执行生产升级。

## Application upgrade

Only upgrade to a registry artifact pinned by a multi-platform manifest digest:

```bash
./bin/upgrade \
  --sub2api-image 'weishaw/sub2api:VERSION@sha256:DIGEST'
```

The upgrade command:

1. Records the current image reference under `.state/previous-images.env`.
2. Creates a logical backup.
3. Updates only `SUB2API_IMAGE` in `.env`.
4. Pulls and starts the new image.
5. Waits for the health endpoint.
6. Attempts to restore the previous image automatically if health never recovers.

If the registry remains unavailable after the bounded retries, the command may use an already cached image only when Docker can resolve the exact requested digest locally. It never substitutes a mutable tag or a different digest.

## Pre-upgrade review

Before running the command:

- Read release notes between the current and target versions.
- Review upstream license and terms for changes.
- Verify the image source/revision labels.
- Confirm the digest covers the intended architectures.
- Check for database migrations, removed configuration, and minimum database versions.
- Run the upgrade and restore procedure on representative non-production data.
- Confirm free disk is sufficient for the new image and backup.

## Manual image rollback

```bash
./bin/rollback
```

This restores only the last recorded Sub2API image reference. It does not reverse PostgreSQL migrations or restore deleted application data.

If an upgrade made an incompatible schema change, restore the backup created immediately before the upgrade:

```bash
./bin/restore \
  --from backups/ai-gateway-YYYYMMDDTHHMMSSZ.tar.gz \
  --confirm-destroy-existing
```

## PostgreSQL and Redis upgrades

Do not use `./bin/upgrade` for database or cache major versions.

For PostgreSQL major upgrades, use an upstream-supported procedure such as logical dump/restore or `pg_upgrade`, validate extensions and collations, and keep the previous data directory until acceptance is complete.

For Redis major upgrades, review persistence format compatibility and restore behavior before changing `REDIS_IMAGE`.

## Rollback acceptance criteria

A rollback is complete only when:

- `/health` passes.
- Administrator login works.
- A test API key can complete a non-sensitive request through an authorized provider.
- Usage and billing records are readable.
- Streaming completes without proxy buffering.
- No migration or authentication errors appear in logs.
