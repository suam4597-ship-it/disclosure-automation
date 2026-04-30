# TW contract template

Use this template after the official Taiwan source surface has been inspected.
Do not fill fields by guesswork.

## Source identity

- source key: `TODO`
- display name: `TODO`
- region code: `tw`
- source type: `TODO`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage`

## Discovery surface

- primary discovery surface: `TODO`
- authoritative detail/archive surface: `TODO`
- whether a CSV/export path exists: `TODO`
- whether a detail page is stable and directly fetchable: `TODO`

## Runtime contract

- adapter key: `TODO`
- parser strategy: `TODO`
- discovery mode: `TODO`
- hydrate mode: `TODO`
- cursor key: `TODO`

## Identity rules

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

## Fixture plan

- isolated sample YAML path: `TODO`
- fixture payload path(s): `TODO`
- bootstrap script path: `TODO`
- isolated server runner path: `TODO`
- dedupe SQL path: `TODO`
- runtime idempotency test path: `TODO`
- HTTP smoke test path: `TODO`

## Verification target

Lock only after all of the following are explicit and green:

- exact `event_id`
- exact `event_family`
- exact `canonical_event_type`
- exact local/UTC published time rules
- repeated poll idempotency
- dedupe SQL clean
- source health healthy
