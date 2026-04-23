# UK FCA NSM contract-freeze input sheet — takeover / scheme — Greencore v0

This sheet translates the Greencore public sample into provisional implementation-ready contract values.
It is still `v0` because CSV-export metadata has not yet been captured.

## Frozen family

- chosen family: `takeover / scheme related update`
- chosen source key: `uk_fca_nsm_takeover_scheme_updates`
- chosen display name: `UK FCA National Storage Mechanism Takeover and Scheme Updates`
- chosen region code: `uk`

## Runtime contract

- adapter key: `uk_fca_nsm_takeover_scheme_updates_v1`
- parser strategy: `discovery result parsing + NSM artefact HTML extraction + RNS header parsing`
- discovery mode: `nsm_search_result_fixture`
- hydrate mode: `artefact_detail_html`
- cursor key: `latest_artefact_token_seen` (provisional)

## Identity rules

- raw document external id rule: `NSM:RNS:<artefact_token>:detail-html`
- document identity rule: `NSM:RNS:<artefact_token>:detail-html`
- raw event key seed: `uk:fca:nsm:rns:<artefact_token>`
- duplicate group seed: `NSM:RNS:<artefact_token>`
- canonical event id shape: `uk.fca.nsm.<issuer_slug>.<yyyymmdd>.<canonical_event_type>.takeover_or_scheme_update.<artefact_token>`

## First event mapping

- first event family: `takeover_or_scheme_update`
- first canonical event type: `TODO`
- source-appropriate canonical item source names: `FCA NSM artefact page` (primary) and `FCA NSM search result` (discovery)

## Fixture scope

- discovery fixture path: `TODO`
- detail fixture path: `TODO`
- linked filing fixture path if required: `none for v0 assumption`
- expected raw-document count per item: `2`
- expected canonical item source count per item: `2`

## Exact values to lock after first green run

- `event_id`: `TODO`
- `event_family`: `takeover_or_scheme_update`
- `canonical_event_type`: `TODO`
- `published_at_local`: `TODO`
- `published_at_utc`: `TODO`
- chosen stable external identity value: `NSM:RNS:5726018`
- chosen cursor value: `5726018`

## Sample anchor

- issuer: `Greencore Group PLC`
- artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- RNS Number: `8538P`
- paired public time: `2025-07-04 13:44:18`

## Decision

Complete only one:

- [x] contract freeze materially advanced — enough to prepare the first implementation PR around the sample contract
- [ ] contract freeze complete — open isolated implementation PR immediately
- [ ] contract freeze incomplete — stay in discovery stage
- [ ] current family rejected — promote backup family

## Remaining blockers before full freeze

- exact canonical event type
- whether NSM CSV export exposes a stronger immutable id or version field than the artefact token
- whether the artefact token is safe enough as the first cursor in repeated-poll semantics
- whether the public artefact page date-only presentation should be supplemented by search/CSV metadata for exact local and UTC lock values
