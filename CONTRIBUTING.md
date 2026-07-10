# Contributing

Contributions that improve reproducibility, security, portability, recovery, or documentation are welcome.

## Scope

This repository is a brand-neutral deployment core. Product websites, client adapters, provider-account workarounds, customer-specific configuration, and production inventory belong elsewhere.

Do not contribute:

- Real domains, IP addresses, emails, API keys, OAuth material, passwords, certificates, database files, backups, or logs.
- Instructions for bypassing provider controls or sharing unauthorized consumer accounts.
- Marketing claims, pricing, or product branding.
- Unpinned container images.

## Development workflow

1. Fork or branch from the current main branch.
2. Keep changes focused and document any new configuration variable.
3. Add comments around non-obvious shell side effects and destructive operations.
4. Run `./tests/validate.sh`.
5. If Docker is available, run `AI_GATEWAY_SMOKE=1 ./tests/smoke.sh` in an isolated environment.
6. Describe security impact, migration requirements, and rollback behavior in the pull request.

## Compatibility changes

Breaking configuration, directory, backup-format, or command changes require:

- A migration guide.
- Explicit impact and rollback notes.
- A changelog entry.
- A release-version change consistent with semantic versioning.

Long-term maintainability takes priority over silently preserving insecure or ambiguous behavior.

## License

Unless explicitly stated otherwise, contributions submitted for inclusion are licensed under Apache License 2.0.
