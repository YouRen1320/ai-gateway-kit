# Upgrade and rollback

## 2026-09 基础镜像补丁

默认模板将 PostgreSQL 18.4 更新为 18.6（保持 Alpine 3.24）、Redis 8.8.0 更新为 8.8.2（保持 Alpine 3.23），Caddy 保持 2.11.4 并固定新的官方重建摘要。Sub2API 版本不变。

此变更只更新模板，不改已有部署的 `.env`。既有实例更新前必须备份数据库、Redis 持久化文件和旧镜像引用，并在隔离环境验证备份恢复、管理员登录及数据读取。

PostgreSQL 官方说明 18.x 内更新无需 dump/restore 迁移，但 18.6 涉及逻辑解码插件白名单、pgcrypto 数据处理及部分扩展索引修复。使用自定义逻辑复制插件、GIN、btree_gist 或 ltree 的部署，应逐项检查[18.6 发布说明](https://www.postgresql.org/docs/release/18.6/)；不能仅以健康接口成功作为生产验收。

回滚时先停止应用写入，恢复保存的镜像引用。若涉及数据清理、扩展索引重建或不兼容的持久化文件，使用升级前备份恢复；不要假定只切换旧镜像即可撤销数据变更。此模板更新不执行生产升级。

## 2026-09-28 Sub2API 0.1.151 → 0.2.9 隔离迁移演练

模板固定镜像从 `weishaw/sub2api:0.1.151@sha256:2ca591c2…` 升级为 `weishaw/sub2api:0.2.9@sha256:1f4a15d2…`（多平台清单摘要，linux/amd64 同日验证）。升级前必须备份数据库与 Redis 持久化文件；此模板更新不执行任何生产升级。

演练证据（2026-09-28，独立 Docker 项目、仅绑定 127.0.0.1 端口、合成数据，不接生产流量与真实模型额度）：

- 同日 trivy 扫描（linux/amd64，有修复版本项）：0.1.151 Critical 0 / High 45 → 0.2.9 Critical 0 / High 4；未新增任何忽略项。
- 迁移脚本审查：两版本间新增 77 个 SQL 迁移，其中 3 个含破坏性语句，逐一定性为安全：180 的 TRUNCATE 是带 2FA 验证的运行时管理功能；236 为幂等的 `groups.model_allowlist` 列修复（NULL 与空白名单语义等价）；238 仅删除三档限额全空、语义上等同"不限额"的配额行（幂等、有上游文档说明）。
- 升级演练：旧版先建立合成数据（管理员、用户、API Key、账号、分组、用量行）并执行 `./bin/backup`，再 `./bin/upgrade` 升级；迁移 212 → 289 全部成功，健康检查通过；用户余额、API Key 状态、用量行成本逐字段一致；管理员与用户登录正常；管理端用量 API 可读取升级前行；网关侧验证了 API Key 鉴权、分组中间件、账号调度、上游地址安全校验（allowlist 开启时强制 HTTPS）与失败语义（502 upstream_error，无部分计费）。
- 未验证：0.2.9 上的端到端模型调用与新增计费行。沙箱环境中定价同步与合成账号不满足新版调度器快照资格（0.1.151 上该路径同样未验证过，因此不构成回归证据）。生产升级前应在可访问定价源的环境补做该项验收。
- 回滚演练发现：`./bin/restore` 会按当前 `.env` 中的镜像自动启动应用；若 `.env` 仍指向新版本，恢复出的旧库会被立即再次前滚迁移。完整回滚的正确顺序是：停止应用写入 → 把 `.env` 的 `SUB2API_IMAGE` 改回旧版摘要 → 再执行 `./bin/restore --from <备份> --confirm-destroy-existing`。`./bin/rollback` 只回退镜像、不撤销数据库迁移。

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
