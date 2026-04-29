# UK FCA NSM contract-freeze input sheet

This sheet translates the completed takeover / scheme inspection into implementation-ready contract values.

## Frozen family

- chosen family: `takeover / scheme related update`
- chosen source key: `uk_fca_nsm_takeover_scheme_updates`
- chosen display name: `UK FCA National Storage Mechanism Takeover and Scheme Updates`
- chosen region code: `uk`

## Runtime contract

- adapter key: `uk_fca_nsm_takeover_scheme_updates_v1`
- parser strategy: `CSV/search-result row parser + NSM artefact HTML detail parser`
- discovery mode: `nsm_csv_export_fixture`
- hydrate mode: `nsm_artefact_html_detail`
- cursor key: `latest_filing_at_and_artefact_id_seen`

## Identity rules

- raw document external id rule: `NSM:RNS:<artefact_token>:<document_role>`
- document identity rule: `NSM:RNS:<artefact_token>:<document_role>`
- raw event key seed: `nsm:rns:<artefact_token>`
- duplicate group seed: `NSM:RNS:<artefact_token>`
- canonical event id shape: `uk.fca_nsm.<issuer_slug>.<filing_date>.takeover_or_scheme_update.<artefact_token_slug>`

## First event mapping

- first event family: `takeover_or_scheme_update`
- first canonical event type: `tender_offer_or_go_private`
- source-appropriate canonical item source names:
  - primary: `FCA National Storage Mechanism RNS Artefact`
  - discovery: `FCA National Storage Mechanism CSV Export Row`

## Fixture scope

- discovery fixture path: `source_payloads/uk_fca_nsm_takeover_scheme_search_results.csv`
- detail fixture path: `source_payloads/uk_fca_nsm_5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- linked filing fixture path if required: `none for v0`
- expected raw-document count per item: `2`
- expected canonical item source count per item: `2`

## Exact values to lock after first green run

- `event_id`: `TODO after first implementation run`
- `event_family`: `takeover_or_scheme_update`
- `canonical_event_type`: `tender_offer_or_go_private`
- `published_at_local`: `2026-04-20T06:00:00+01:00` provisional from CSV publication time; confirm during implementation
- `published_at_utc`: `2026-04-20T05:00:00.000000Z` provisional from BST conversion; confirm during implementation
- chosen stable external identity value: `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289`
- chosen cursor value: `2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289`

## Decision

- [x] contract freeze complete — open isolated implementation PR
- [ ] contract freeze incomplete — stay in discovery stage
- [ ] current family rejected — promote backup family

## Remaining first-run confirmation

The contract is ready for an isolated v0 implementation PR.
During first-run verification, confirm whether the direct NSM artefact body is sufficient or whether a linked payload should be added in a follow-up hardening PR.
