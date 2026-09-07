# AI Gateway Kit

简体中文 | [English](README.md)

一个品牌无关、安全优先的 AI API 网关部署工具包，适合在单台 Linux 服务器上运行。它使用 Docker Compose 编排第三方 Sub2API、PostgreSQL 和 Redis，并可选用 Caddy 自动配置 HTTPS。

本仓库只包含部署自动化，不包含 Sub2API 源码、客户数据、供应商凭据、VPN/住宅代理配置、聊天 UI 或品牌网站。

## 目标

- 同一套部署核心可被不同产品和品牌直接复用。
- 生产凭据、客户数据、日志和备份永远不进入 Git。
- 新服务器可以从零安装、诊断、备份、恢复和回滚。
- 所有容器镜像使用不可变 digest 锁定。
- 默认只监听本机，数据库和 Redis 不暴露宿主机端口。
- 默认禁止明文 HTTP 上游和私网/回环上游地址。

## 使用边界

使用者必须自行获得上游模型供应商授权，并遵守相关服务条款、隐私要求、支付规则和所在地法律。本项目默认只支持你有权使用的官方 API 或商业凭据，不授权共享个人订阅账号、转售账号访问权、绕过供应商限制或把住宅代理当作公共服务能力。

本项目与 OpenAI、Anthropic、Google、Sub2API、Caddy 等第三方无隶属或官方合作关系。

## 相关项目

- [Transfer-Station](https://github.com/YouRen1320/Transfer-Station)：面向个人实验环境的 Sub2API 部署整合实例。
- [open-gateway-starter](https://github.com/YouRen1320/open-gateway-starter)：面向网关产品介绍与演示的前端起步项目。

三个仓库职责独立，本项目不依赖另外两个仓库的源码。生产部署优先使用本仓库的安全默认值、诊断、备份与回滚流程。

## 环境要求

- 64 位 Linux；推荐 Debian 12 或 Ubuntu 24.04。
- Docker Engine 24+ 和 Docker Compose v2。
- `openssl`、`curl`、`tar`、`awk`。
- 运行可选容器漏洞扫描时还需要 `jq`。
- 小型生产实例建议至少 2 GB 内存、10 GB 可用磁盘。
- 使用内置 HTTPS 代理时，需要一个已经解析到服务器的域名。

## 快速开始

克隆仓库后执行一次初始化：

```bash
./bin/setup \
  --domain api.example.com \
  --admin-email admin@example.com \
  --timezone Asia/Shanghai \
  --project-name my-gateway
```

初始化会生成 `.env`，其中包含数据库、Redis、管理员、JWT 和 TOTP 强随机密钥。密钥不会打印到终端；已有 `.env` 时脚本会拒绝覆盖，避免现有数据失去解密凭据。

运行预检：

```bash
./bin/doctor
```

如果已有 Nginx、Caddy 或负载均衡器，只启动内部服务：

```bash
docker compose --env-file .env -f compose.yaml up -d
curl http://127.0.0.1:8080/health
```

如果使用内置 Caddy 自动 HTTPS：

```bash
docker compose \
  --env-file .env \
  -f compose.yaml \
  -f compose.proxy.yaml \
  up -d
```

打开 `https://api.example.com`，使用 `.env` 中的 `ADMIN_EMAIL` 和 `ADMIN_PASSWORD` 登录，然后只配置已经获得合法授权的上游凭据。

## 常用命令

```bash
make doctor                        # 环境和安全预检
make up                            # 不启用内置公网代理
make up-proxy                      # 启用 Caddy HTTPS
make logs                          # 查看应用日志
./bin/backup                       # 不含 .env，但仍包含敏感业务数据
./bin/backup --with-secrets        # 包含 .env，必须加密保存
```

恢复是破坏性操作，必须显式确认：

```bash
./bin/restore \
  --from backups/ai-gateway-YYYYMMDDTHHMMSSZ.tar.gz \
  --confirm-destroy-existing
```

升级必须使用包含 digest 的镜像地址：

```bash
./bin/upgrade \
  --sub2api-image 'weishaw/sub2api:VERSION@sha256:DIGEST'
```

升级失败时会尝试恢复旧镜像，也可以执行 `./bin/rollback`。镜像回滚不会自动回滚数据库迁移，具体见[升级和回滚](docs/UPGRADING.md)。

## 项目结构

```text
ai-gateway-kit/
├── bin/                     初始化、诊断、备份、恢复和升级工具
├── config/Caddyfile         可选 HTTPS 反向代理
├── docs/                    架构、配置、运维和合规文档
├── tests/                   静态检查和隔离运行测试
├── compose.yaml             应用、数据库和缓存
├── compose.proxy.yaml       可选公网 TLS 边缘
└── .env.example             完整配置契约
```

运行数据位于 `runtime/`，备份位于 `backups/`，升级状态位于 `.state/`。这些目录和 `.env` 都被 Git 忽略。

## 详细文档

- [架构与信任边界](docs/ARCHITECTURE.md)
- [配置参考](docs/CONFIGURATION.md)
- [日常运维和恢复](docs/OPERATIONS.md)
- [升级和回滚](docs/UPGRADING.md)
- [品牌复用方式](docs/REBRANDING.md)
- [合规与第三方边界](docs/COMPLIANCE.md)
- [容器漏洞基线](docs/SECURITY_BASELINE.md)
- [安全漏洞报告](SECURITY.md)
- [第三方许可证说明](THIRD_PARTY_NOTICES.md)
- [支持范围](SUPPORT.md)
- [发布流程](docs/RELEASING.md)
- [0.1.0 发布说明](docs/RELEASE_NOTES_0.1.0.md)

## 验证

静态检查：

```bash
./tests/validate.sh
```

镜像扫描会下载已锁定的 Trivy 扫描器、漏洞数据库和全部部署镜像，因此也必须显式开启：

```bash
AI_GATEWAY_IMAGE_SCAN=1 ./tests/scan-images.sh
```

容器级测试会下载镜像、启动隔离容器，并验证备份恢复，因此必须显式开启：

```bash
AI_GATEWAY_SMOKE=1 ./tests/smoke.sh
```

## 许可证

本仓库原创内容采用 Apache License 2.0。第三方镜像继续适用各自许可证和条款，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
