# Rebranding and product overlays

The deployment core is intentionally brand-neutral. A product should consume it through configuration rather than copying and editing infrastructure scripts.

## What belongs in this repository

- Container orchestration.
- Safe configuration defaults.
- TLS proxy templates.
- Backup, restore, diagnosis, and upgrade workflows.
- Generic API usage examples.

## What belongs in a product repository

- Product name, logo, colors, screenshots, and marketing content.
- Website, dashboard extensions, and client applications.
- Product-specific pricing and feature claims.
- Product release notes and end-user support channels.

## What must remain private

- Production domains and server inventory when disclosure is unnecessary.
- Real `.env` files, provider credentials, customer data, database snapshots, and logs.
- Payment credentials, DNS tokens, SSH configuration, certificates, and private keys.
- Incident notes containing identifiers or credentials.
- Provider-account workarounds, residential-proxy credentials, or risk-control bypass procedures.

## Recommended layout

```text
ai-gateway-kit/       public reusable deployment core
product-web/          public product website or UI
product-cli/          public client configuration tool
product-ops/          private production inventory and runbooks
```

## Creating a new product deployment

1. Use a release of this kit rather than copying an arbitrary working directory.
2. Run `./bin/setup` with a unique Compose project name, domain, and administrator email.
3. Keep product-specific reverse-proxy additions in a small documented override file.
4. Store production `.env` in an approved secret manager or encrypted backup.
5. Link the product documentation to this kit's exact release.
6. Test backup and restore before accepting real users.

Do not replace generic placeholders in `.env.example` with real brand data. Example files are copied by every downstream user and should remain safe and neutral.
