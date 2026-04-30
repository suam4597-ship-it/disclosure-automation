# JP contract-freeze close-out preflight

This document closes the immediate post-discovery preflight after PR #39 and defines the remaining evidence needed before JP TDnet contract-freeze.

This is docs-only. It does not freeze the final runtime contract and does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Current status

- PR #39 `JP official disclosure discovery-first kickoff`: merged
- PR #39 merge commit: `2b5d9b09ae969eb09341eedb0394c55e3d7d56aa`
- current branch: `chatgpt-jp-tdnet-contract-freeze-v1`
- current phase: JP TDnet/JPX contract-freeze preflight
- runtime status: not started

## Current locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Preflight result

The preflight keeps TDnet / JPX as the preferred JP first-source candidate, but does not yet freeze the runtime contract.

Reason:

- source authority is strong enough for `official_exchange_storage`
- official JPX pages establish TDnet as the timely disclosure network and describe the public Company Announcements Disclosure Service
- paid TDnet documentation confirms stronger TDnet identity fields exist in the broader source model
- however, the open public v0 must still capture one deterministic public row and prove that identity/cursor fields are visible or derivable without paid access and without title-only heuristics

## Preferred candidate path

```text
source candidate: TDnet / JPX Company Announcements Disclosure Service
source_key candidate: jp_tdnet_timely_disclosure
adapter_key candidate: jp_tdnet_timely_disclosure_v1
region_code: jp
source_class: regulatory_filing_feed
source_tier candidate: official_exchange_storage
first-family candidate: material_information_update / timely disclosure update
```

## Backup candidate path

```text
backup source: EDINET
backup source tier: official_regulatory_storage
backup family: periodic/statutory disclosure
backup reason: official FSA-operated disclosure API, better suited to statutory securities reports than first timely-disclosure lane
```

Use EDINET only if TDnet public sample capture fails the identity/cursor requirements.

## Documents added by this preflight package

```text
apps/backend/disclosure_api/docs/jp_tdnet_public_surface_inspection.md
apps/backend/disclosure_api/docs/jp_tdnet_source_findings.md
apps/backend/disclosure_api/docs/jp_tdnet_candidate_contract_v0.md
apps/backend/disclosure_api/docs/jp_tdnet_contract_freeze_input_sheet.md
apps/backend/disclosure_api/docs/jp_contract_freeze_closeout_preflight.md
```

## Contract fields still not frozen

These must be filled from one public sample before runtime can start:

```text
sample issuer
sample security code
sample title
sample source category/material category
sample publication datetime local
sample publication datetime UTC
sample detail URL
sample attachment URL
stable_external_id
cursor_key
cursor_value
event_family
canonical_event_type
event_id
raw document external IDs
minimum raw-document set
```

## Recommended sample-capture sequence

1. Open the public Company Announcements Disclosure Service.
2. Capture one latest timely disclosure row from the 31-day window.
3. Record row fields in `jp_tdnet_contract_freeze_input_sheet.md`.
4. Inspect whether the row or linked artefacts expose one of:
   - disclosure number
   - disclosure history number
   - public item code
   - stable PDF/document token
5. If the latest-row surface cannot produce a deterministic fixture, repeat against JPX Listed Company Search for a historical TDnet row.
6. If both TDnet paths fail identity/cursor requirements, evaluate EDINET as backup.

## Identity/cursor decision gate

Freeze TDnet only if the sample supports one of these identities:

```text
TDNET:<disclosure_number>
TDNET:<disclosure_number>:<disclosure_history_number>
TDNET:<public_item_code>:<file_token>
TDNET:<pdf_url_token>
TDNET:<security_code>:<YYYYMMDDHHMMSS_JST>:<sequence_or_token>
```

Freeze TDnet only if the sample supports one of these cursor shapes:

```text
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>
<YYYY-MM-DDTHH:MM:SS+09:00>|<public_item_code>
<YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>
```

Reject the sample if identity or cursor requires title-only matching.

## Runtime workset boundary after freeze

The later runtime PR, if TDnet is frozen, should stay limited to:

```text
one source: jp_tdnet_timely_disclosure
one adapter: jp_tdnet_timely_disclosure_v1
one family: chosen from the captured sample
one fixture item: the frozen sample only
```

Do not include:

- broad JP all-disclosures ingestion
- multiple TDnet families
- live pagination beyond the single fixture path
- EDINET implementation in the same PR
- news overlay
- cross-source merge
- broad CN expansion

## Close-out result

JP TDnet contract-freeze is not complete yet.

This preflight package is complete when:

- it documents the official TDnet/JPX source path
- it defines candidate identity/cursor rules
- it provides a sample-capture input sheet
- it blocks runtime work until one deterministic public sample is captured

Next step:

```text
Fill jp_tdnet_contract_freeze_input_sheet.md with one public sample, then produce a true JP TDnet contract-freeze close-out if the sample satisfies the gate.
```
