# CN contract template

Use this template after the official China source surface has been inspected.
Do not fill fields by guesswork.

## Source identity

- source key: `TODO`
- display name: `TODO`
- region code: `cn`
- source type: `TODO`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage` or `official_exchange_storage`

## Discovery surface

- primary discovery surface: `TODO`
- authoritative detail/archive surface: `TODO`
- whether a CSV/export/API path exists: `TODO`
- whether a detail page is stable and directly fetchable: `TODO`
- whether an attachment/PDF is required for canonical facts: `TODO`
- whether category/family filters are deterministic: `TODO`

## Runtime contract

- adapter key: `TODO`
- parser strategy: `TODO`
- discovery mode: `TODO`
- hydrate mode: `TODO`
- cursor key: `TODO`
- cursor value shape: `TODO`

## Identity rules

- stable external identity rule: `TODO`
- stable external identity sample value: `TODO`
- raw document external id rule: `TODO`
- document identity rule: `TODO`
- raw event key seed: `TODO`
- duplicate group seed: `TODO`
- canonical event id shape: `TODO`

## First thin-slice scope

Freeze one family only:

- event family: `TODO`
- canonical event type: `TODO`
- expected first fixture item count: `1`
- expected raw document count per item: `TODO`
- expected canonical item source count per item: `TODO`

## Sample facts to capture

- sample company / issuer: `TODO`
- sample security code: `TODO`
- sample title: `TODO`
- sample source category: `TODO`
- sample publication datetime local: `TODO`
- sample publication datetime UTC: `TODO`
- sample detail URL: `TODO`
- sample attachment URL if required: `TODO`

## Source-appropriate canonical item source names

- official storage name: `TODO`
- official source name: `TODO`
- discovery source name: `TODO`
- primary disclosure document source name: `TODO`

## Fixture plan for later implementation PR

Do not create these paths in this discovery-only PR.
Record the intended later paths here after contract freeze:

- isolated sample YAML path: `TODO`
- fixture payload path(s): `TODO`
- bootstrap script path: `TODO`
- isolated server runner path: `TODO`
- dedupe SQL path: `TODO`
- runtime idempotency test path: `TODO`
- HTTP smoke test path: `TODO`

## Verification target for later lock PR

Lock only after all of the following are explicit and green:

- exact `event_id`
- exact `event_family`
- exact `canonical_event_type`
- exact local/UTC published time rules
- repeated poll idempotency
- dedupe SQL clean
- source health healthy
- cursor key/value present
