# UK FCA NSM contract-freeze input sheet

Fill this sheet only after the public surface inspection worksheet has been completed for one family.
The goal is to translate live inspection into implementation-ready contract values.

## Frozen family

- chosen family: `TODO`
- chosen source key: `TODO`
- chosen display name: `TODO`
- chosen region code: `uk`

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

## First event mapping

- first event family: `TODO`
- first canonical event type: `TODO`
- source-appropriate canonical item source names: `TODO`

## Fixture scope

- discovery fixture path: `TODO`
- detail fixture path: `TODO`
- linked filing fixture path if required: `TODO`
- expected raw-document count per item: `TODO`
- expected canonical item source count per item: `TODO`

## Exact values to lock after first green run

- `event_id`: `TODO`
- `event_family`: `TODO`
- `canonical_event_type`: `TODO`
- `published_at_local`: `TODO`
- `published_at_utc`: `TODO`
- chosen stable external identity value: `TODO`
- chosen cursor value: `TODO`

## Decision

Complete only one:

- [ ] contract freeze complete — open isolated implementation PR
- [ ] contract freeze incomplete — stay in discovery stage
- [ ] current family rejected — promote backup family
