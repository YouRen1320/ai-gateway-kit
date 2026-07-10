# Operations and recovery

## Start and stop

Run the application behind an existing reverse proxy:

```bash
docker compose --env-file .env -f compose.yaml up -d
```

Run it with the bundled Caddy TLS edge:

```bash
docker compose \
  --env-file .env \
  -f compose.yaml \
  -f compose.proxy.yaml \
  up -d
```

Stop containers without deleting data:

```bash
docker compose --env-file .env -f compose.yaml stop
```

Remove containers and networks while retaining bind-mounted state:

```bash
docker compose \
  --env-file .env \
  -f compose.yaml \
  -f compose.proxy.yaml \
  down
```

## Health and logs

```bash
./bin/doctor
docker compose --env-file .env -f compose.yaml ps
docker compose --env-file .env -f compose.yaml logs --tail=200 sub2api
curl --fail http://127.0.0.1:8080/health
```

Do not attach raw logs to public issues without reviewing them for API keys, email addresses, prompts, upstream responses, IP addresses, and account identifiers.

## Backups

The default backup includes:

- A consistent PostgreSQL logical dump.
- Application runtime state, excluding application logs.
- A forced Redis snapshot and Redis runtime files.
- Image and project metadata.
- SHA-256 checksums for every payload.

```bash
./bin/backup
```

Every backup contains sensitive application and customer data and must be encrypted before offsite storage. For full disaster recovery, include `.env` explicitly:

```bash
./bin/backup --with-secrets
```

Backups containing `config.env` additionally contain the credentials needed to decrypt and reconnect the deployment. Restrict access, and test decryption and restore periodically. Keeping only an untested backup is not a recovery plan.

Suggested schedule for a small service:

- Daily logical database backup.
- Weekly encrypted full backup with secrets.
- Monthly restore exercise on an isolated host.
- Backup immediately before every application upgrade or configuration migration.

## Restore

Restoring is intentionally explicit because it replaces the current database and runtime state:

```bash
./bin/restore \
  --from backups/ai-gateway-YYYYMMDDTHHMMSSZ.tar.gz \
  --confirm-destroy-existing
```

Use `--restore-secrets` only on a clean disaster-recovery destination that contains no runtime data, containers, or named volumes for the current or archived Compose project. It restores the infrastructure passwords that initialize PostgreSQL and Redis, so the command deliberately refuses to replace secrets on an existing stack. A fresh clone does not need `./bin/setup` first:

```bash
./bin/restore \
  --from /secure/path/ai-gateway-YYYYMMDDTHHMMSSZ.tar.gz \
  --confirm-destroy-existing \
  --restore-secrets
```

For an in-place data restore, omit `--restore-secrets`; the current `.env` remains in place. Rotate credentials as a separate, planned operation rather than by importing another deployment's environment file.

Before replacement, the restore tool creates a safety backup when a database is running. Existing application and Redis directories are moved under `.state/pre-restore-*` instead of being deleted. If the restore fails after the database has been replaced, use the safety backup for recovery.

## Reverse proxy

Caddy is optional. If an existing edge proxy is used, it must:

- Terminate TLS.
- Preserve `Host`, `X-Forwarded-For`, `X-Real-IP`, and `X-Forwarded-Proto`.
- Disable response buffering for SSE streaming.
- Allow request duration and body size appropriate for image generation.
- Forward WebSocket upgrades if enabled by the application.
- Avoid exposing the loopback application port directly to the internet.

## Monitoring baseline

At minimum, alert on:

- `/health` failing for more than two consecutive checks.
- Container restart loops or unhealthy state.
- Disk use above 80% and free space below the largest expected backup.
- Memory pressure or kernel OOM events.
- PostgreSQL backup failure or backup age beyond policy.
- TLS certificate renewal failure.
- Sudden authentication failures, request spikes, or unexplained upstream cost changes.

## Incident response

For a suspected credential leak:

1. Revoke or rotate the affected provider credential first.
2. Rotate local administrator credentials and sessions if exposed.
3. Preserve relevant logs privately.
4. Determine whether prompts, user identifiers, billing data, or upstream tokens were accessed.
5. Follow applicable notification and contractual requirements.
6. Remove sensitive data from repository history only after rotation.
