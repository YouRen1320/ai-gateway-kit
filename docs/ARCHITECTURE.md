# Architecture

## Scope

AI Gateway Kit is a deployment boundary, not an application fork. It connects independently distributed containers and keeps all mutable state outside the Git repository.

```text
Internet
   │
   ▼
Caddy :443 (optional, frontend network)
   │ HTTPS termination, request-size limit, streaming proxy
   ▼
Sub2API :8080 (frontend + internal backend networks)
   ├── PostgreSQL :5432 (internal backend network only)
   └── Redis :6379 (internal backend network only, password required)
```

Without Caddy, Sub2API is published only on `127.0.0.1:8080` by default. An existing Nginx, Caddy, load balancer, or private tunnel can connect to that loopback port.

## Trust boundaries

- **Public edge:** Caddy is the only bundled service intended to receive internet traffic.
- **Application:** Sub2API validates users and API keys and performs upstream requests.
- **State network:** PostgreSQL and Redis have no host ports and use an internal Docker network.
- **Host state:** `runtime/` contains databases, application configuration, logs, OAuth material and other sensitive state. It is never source-controlled.
- **Source repository:** contains templates and automation only. It must remain safe to publish.

## Data ownership

| Path | Contents | Backup expectation |
|---|---|---|
| `runtime/postgres/` | accounts, usage, billing and application records | Logical `pg_dump` is authoritative |
| `runtime/redis/` | cache, queues and ephemeral coordination | Saved as supplemental recovery state |
| `runtime/app/` | generated application configuration and logs | Back up configuration; logs are excluded by default |
| `.env` | encryption, authentication and database secrets | Back up only with `--with-secrets`, then encrypt offsite |

## Design decisions

- No fixed container names, so multiple deployments can coexist under different Compose project names.
- Images are pinned by multi-platform manifest digest for reproducibility.
- PostgreSQL and Redis are not directly exposed to the host.
- The backend network is marked internal; only Sub2API joins both networks.
- Sub2API's URL hostname allowlist and resolved-IP SSRF checks are enabled with HTTPS-only, public-address defaults.
- Provider integrations are configured after deployment and are not stored in Git.
- Chat UI, marketing site, CLI adapters and production inventory are separate projects with separate release cycles.
