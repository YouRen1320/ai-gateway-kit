# Security policy

## Supported versions

Security fixes are provided for the latest released minor version of this deployment kit. Upstream container vulnerabilities must also be reported to and fixed by the relevant upstream project.

The reviewed image versions, scan policy, unresolved upstream findings, and any time-limited exception are published in [the container vulnerability baseline](docs/SECURITY_BASELINE.md). A weekly workflow fails on unacknowledged fixable critical findings; high findings remain visible and require release-time review.

## Reporting a vulnerability

Use GitHub's private **Report a vulnerability** feature for the repository. Do not open a public issue for a vulnerability that could expose credentials, customer data, authentication bypasses, request contents, or infrastructure details.

Include:

- The affected kit version and exact image digests.
- A concise impact statement.
- Reproduction steps using synthetic data.
- Whether credentials or personal data may have been exposed.
- Suggested mitigations, if known.

Never include live API keys, `.env`, database files, logs with prompts, private keys, or customer identifiers. Revoke or rotate exposed credentials before reporting.

## Security model

The project assumes:

- Docker and the host operating system are trusted and patched.
- `.env`, `runtime/`, `backups/`, and `.state/` remain private.
- Public traffic reaches the gateway only through a reviewed TLS proxy.
- Operators configure only provider credentials they are authorized to use.
- Database and Redis services remain on the internal Docker network.

The project does not claim to protect a malicious host administrator or a compromised Docker daemon.

## Disclosure process

Maintainers should acknowledge a complete report, reproduce it privately, coordinate with affected upstream projects when necessary, prepare a fix and upgrade guidance, and publish an advisory after users have a reasonable opportunity to update.
