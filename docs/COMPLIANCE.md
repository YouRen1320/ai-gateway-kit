# Compliance and third-party boundaries

This document is operational guidance, not legal advice.

## Code publication versus service operation

Publishing deployment code does not grant permission to use a model provider's accounts, subscriptions, APIs, trademarks, or payment systems. Operators must independently verify:

- Provider authorization for the intended account and redistribution model.
- Applicable API, consumer, business, and reseller terms.
- Privacy notices, data-processing agreements, retention, deletion, and user rights.
- Content-safety, abuse-handling, age, and supported-region requirements.
- Business registration, tax, invoicing, payment, refund, and consumer-protection obligations.
- Cybersecurity, incident-reporting, record-retention, and cross-border data rules.

## Supported authorization model

The documented default is an operator-owned, authorized API or business credential used in accordance with its provider agreement. The public repository must not contain provider credentials.

The following are intentionally not part of this kit's supported quick start:

- Sharing a personal consumer account with unrelated users.
- Reselling or leasing account access without written authorization.
- Buying, selling, or transferring provider API keys.
- Bypassing provider rate limits, safety controls, region restrictions, or account protections.
- Publishing residential-proxy credentials or techniques intended to evade risk controls.

## Third-party software

This kit references external container images but does not vendor their binaries or source code. Each image remains subject to its own license and terms. See [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) and verify the exact license at every upgrade.

Sub2API's current upstream repository contains a LGPL-3.0 license file while its README also contains a no-commercial-authorization statement. Because those descriptions may not express the same commercial boundary, operators should obtain clarification from upstream before relying on commercial reuse.

## Branding and claims

- Do not imply affiliation with model providers or upstream projects.
- Follow provider trademark and brand guidelines.
- Do not publish unverified model names, prices, uptime, user counts, security certifications, or SLA claims.
- Clearly label examples and simulated data.
- State which component is maintained by whom and where vulnerabilities should be reported.

## Data inventory

Before serving users, document at least:

- What request content, account data, IP addresses, usage data, and payment data are collected.
- Where each data class is stored and transmitted.
- Which providers and subprocessors receive it.
- Retention and deletion periods.
- Encryption, access-control, backup, and incident procedures.
- Whether operators can read prompts or outputs and under what controls.
