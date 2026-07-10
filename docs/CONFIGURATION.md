# Configuration reference

`./bin/setup` creates `.env` from `.env.example` and replaces every secret placeholder. Treat `.env` as production credentials: keep mode `600`, never attach it to issues, and never commit it.

## Identity and public access

| Variable | Default | Purpose |
|---|---|---|
| `COMPOSE_PROJECT_NAME` | `ai-gateway` | Isolates container, network and volume names |
| `GATEWAY_DOMAIN` | `api.example.com` | Hostname served by optional Caddy |
| `ACME_EMAIL` | `admin@example.com` | ACME certificate contact |
| `ADMIN_EMAIL` | `admin@example.com` | Initial gateway administrator |
| `TZ` | `UTC` | Application, database and log timezone |
| `PROXY_HTTP_PORT` | `80` | Host port published by Caddy for HTTP redirects |
| `PROXY_HTTPS_PORT` | `443` | Host TCP/UDP port published by Caddy for HTTPS and HTTP/3 |
| `BIND_HOST` | `127.0.0.1` | Host interface for direct Sub2API access |
| `SERVER_PORT` | `8080` | Host port for direct Sub2API access |

Do not change `BIND_HOST` to `0.0.0.0` on an internet-facing server unless an external firewall and a documented threat model require it.

## Immutable images

`SUB2API_IMAGE`, `POSTGRES_IMAGE`, `REDIS_IMAGE`, and `CADDY_IMAGE` must end with `@sha256:<64 hex characters>`. Tags are retained for readability, but the digest determines the actual artifact.

The reviewed versions and source revisions are recorded in [UPSTREAM.md](UPSTREAM.md). Do not update PostgreSQL or Redis major versions through the Sub2API upgrade script.

## Generated secrets

| Variable | Consumer | Rotation impact |
|---|---|---|
| `POSTGRES_PASSWORD` | Sub2API and PostgreSQL | Requires coordinated database credential rotation |
| `REDIS_PASSWORD` | Sub2API and Redis | Requires coordinated cache credential rotation |
| `ADMIN_PASSWORD` | Initial administrator | Rotate through the application after first sign-in |
| `JWT_SECRET` | Login/session tokens | Rotation invalidates existing sessions |
| `TOTP_ENCRYPTION_KEY` | Stored two-factor secrets | Incorrect rotation can invalidate all TOTP registrations |

Never regenerate `.env` against existing data. The setup script intentionally refuses to do so.

## Database and cache

The default database pool is intentionally modest for a single small server. Increase it only after measuring database capacity.

| Variable | Default |
|---|---:|
| `DATABASE_MAX_OPEN_CONNS` | 50 |
| `DATABASE_MAX_IDLE_CONNS` | 10 |
| `DATABASE_CONN_MAX_LIFETIME_MINUTES` | 30 |
| `DATABASE_CONN_MAX_IDLE_TIME_MINUTES` | 5 |
| `REDIS_POOL_SIZE` | 256 |
| `REDIS_MIN_IDLE_CONNS` | 10 |

## Security controls

Production defaults enable Sub2API's hostname allowlist and SSRF checks, reject plaintext upstream URLs, and reject private/loopback destinations:

```dotenv
SECURITY_URL_ALLOWLIST_ENABLED=true
SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP=false
SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS=false
SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS=api.openai.com,api.anthropic.com,...
```

`SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS`, `SECURITY_URL_ALLOWLIST_PRICING_HOSTS`, and `SECURITY_URL_ALLOWLIST_CRS_HOSTS` are comma-separated hostname lists. Add the exact host for an authorized custom provider before configuring it in the application. A leading `*.` is supported for a reviewed domain family, but exact names are preferable.

Do not set `SECURITY_URL_ALLOWLIST_ENABLED=false` merely to make an unknown provider work. In Sub2API 0.1.151 that disables hostname allowlisting and resolved-IP SSRF checks; `ALLOW_PRIVATE_HOSTS=false` does not restore those checks while the allowlist is disabled. Disabling the allowlist or changing either restriction to `true` is a security exception. Document why it is needed, who approved it, its expiration date, and what egress controls prevent SSRF or credential exposure.

## Optional provider settings

The example exposes only empty configuration slots. Do not put real OAuth secrets in `.env.example` or documentation.

- `GEMINI_OAUTH_CLIENT_ID`
- `GEMINI_OAUTH_CLIENT_SECRET`
- `GEMINI_OAUTH_SCOPES`
- `UPDATE_PROXY_URL`

Prefer official business/API credentials that explicitly permit your deployment model. Consumer-account sharing and resale are outside this kit's supported path.
