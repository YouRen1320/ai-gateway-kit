# AI Gateway Kit

[简体中文](README.zh-CN.md) | English

A brand-neutral, security-first deployment kit for running an AI API gateway on a single Linux server. The kit orchestrates an upstream Sub2API image with PostgreSQL and Redis, and can optionally terminate TLS with Caddy.

This repository contains deployment automation only. It does not vendor Sub2API, model-provider software, customer data, provider credentials, VPN software, residential-proxy configuration, a chat UI, or a branded marketing website.

## Design goals

- Reuse the same deployment foundation across different products and brands.
- Keep production secrets and customer data outside source control.
- Make a fresh installation reproducible and diagnosable.
- Pin every container image by an immutable digest.
- Use conservative production defaults: loopback binding, TLS at the edge, authenticated Redis, and blocked plaintext/private upstream URLs.
- Make backup, restore, upgrade, and image rollback explicit operations.

## Important usage boundary

You are responsible for obtaining authorization from every upstream model provider and complying with their terms, privacy requirements, payment rules, and local laws. The default documentation assumes credentials that you are authorized to use. It does not authorize sharing consumer accounts, reselling account access, bypassing provider controls, or using subscription OAuth credentials as a public service.

Sub2API is an independent third-party project. This kit is not affiliated with OpenAI, Anthropic, Google, Sub2API, or Caddy.

## Prerequisites

- A 64-bit Linux server; Debian 12 or Ubuntu 24.04 are recommended.
- Docker Engine 24+ and Docker Compose v2.
- `openssl`, `curl`, `tar`, and `awk`.
- `jq` when running the optional container vulnerability scan.
- At least 2 GB RAM and 10 GB free disk for a small production instance.
- A domain pointing at the server if the bundled TLS proxy is enabled.

## Quick start

Clone the repository, then initialize it once:

```bash
./bin/setup \
  --domain api.example.com \
  --admin-email admin@example.com \
  --timezone UTC \
  --project-name my-gateway
```

The setup command creates `.env` with strong random database, Redis, administrator, JWT, and TOTP secrets. It never prints those secrets and refuses to overwrite an existing `.env`.

Run the preflight checks:

```bash
./bin/doctor
```

For local access behind an existing reverse proxy:

```bash
docker compose --env-file .env -f compose.yaml up -d
curl http://127.0.0.1:8080/health
```

For the bundled Caddy proxy with automatic HTTPS:

```bash
docker compose \
  --env-file .env \
  -f compose.yaml \
  -f compose.proxy.yaml \
  up -d
```

Open `https://api.example.com`, sign in with the administrator email and the generated `ADMIN_PASSWORD` stored in `.env`, then configure only provider credentials you are authorized to use.

## Common operations

```bash
make doctor       # validate secrets, image pins, security defaults and Compose
make up           # start without the bundled public proxy
make up-proxy     # start with Caddy and automatic HTTPS
make logs         # follow application logs
./bin/backup      # sensitive database/runtime backup, without .env
./bin/backup --with-secrets
```

A destructive restore requires an explicit confirmation flag:

```bash
./bin/restore \
  --from backups/ai-gateway-YYYYMMDDTHHMMSSZ.tar.gz \
  --confirm-destroy-existing
```

Upgrade only to an image reference pinned by digest:

```bash
./bin/upgrade \
  --sub2api-image 'weishaw/sub2api:VERSION@sha256:DIGEST'
```

If the new image is unhealthy, the upgrade command attempts an image rollback. A manual retry is available through `./bin/rollback`. Image rollback does not reverse database migrations; see [the upgrade guide](docs/UPGRADING.md).

## Repository layout

```text
ai-gateway-kit/
├── bin/                     setup, diagnosis, backup, restore and upgrade tools
├── config/Caddyfile         optional TLS reverse proxy
├── docs/                    architecture, configuration and operations guides
├── tests/                   static and opt-in runtime checks
├── compose.yaml             private application/database/cache stack
├── compose.proxy.yaml       optional public TLS edge
└── .env.example             documented configuration contract
```

Runtime files are created under `runtime/`; backups under `backups/`; upgrade state under `.state/`. All are ignored by Git.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Configuration reference](docs/CONFIGURATION.md)
- [Operations and recovery](docs/OPERATIONS.md)
- [Upgrade and rollback](docs/UPGRADING.md)
- [Rebranding and product overlays](docs/REBRANDING.md)
- [Compliance and third-party boundaries](docs/COMPLIANCE.md)
- [Container vulnerability baseline](docs/SECURITY_BASELINE.md)
- [Security policy](SECURITY.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Support policy](SUPPORT.md)
- [Release process](docs/RELEASING.md)
- [0.1.0 release notes](docs/RELEASE_NOTES_0.1.0.md)

## Validation

```bash
./tests/validate.sh
```

An image scan is also opt-in because it downloads a pinned Trivy scanner, its vulnerability database, and all deployment images:

```bash
AI_GATEWAY_IMAGE_SCAN=1 ./tests/scan-images.sh
```

The runtime smoke test is deliberately opt-in because it pulls images and creates temporary containers:

```bash
AI_GATEWAY_SMOKE=1 ./tests/smoke.sh
```

## License

The original files in this repository are licensed under Apache License 2.0. Third-party images retain their own licenses and terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
