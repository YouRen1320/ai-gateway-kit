# Upgrade and rollback

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
