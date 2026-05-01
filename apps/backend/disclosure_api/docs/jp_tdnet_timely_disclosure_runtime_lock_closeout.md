# JP TDnet timely disclosure runtime lock close-out

This document closes out the JP TDnet timely disclosure runtime lock after the implementation and preflight PRs.

## Runtime lock status

```text
jp_tdnet_timely_disclosure: locked
```

## Implementation and preflight

```text
implementation PR: #45
implementation merge SHA: 2f6ec8f22689e20b67ab62d604f593347ec85664
preflight PR: #46
preflight merge SHA: 72e5cfb3104067399008a7b41b0d3633926ce380
verification branch: chatgpt-jp-tdnet-runtime-lock-closeout-v1
verification base: sec-thin-slice-reconcile-v1 at 72e5cfb3104067399008a7b41b0d3633926ce380
```

## Verification result

```text
automated tests: PASS
manual smoke: PASS
dedupe SQL: PASS
code patch required after verification: yes
```

The required patch is limited to the isolated JP TDnet source registry sample: `source_type` was changed from `public_web` to `api` so it satisfies the existing `source_registry_source_type_check` database constraint. No ingestion breadth, live pagination, category inference, or cross-source behavior was added.

## Test commands

```powershell
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Observed:

```text
jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
jp_tdnet_timely_disclosure_http_smoke_test.exs: PASS - 1 test, 0 failures
```

## Manual smoke

Manual smoke followed:

```text
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_manual_smoke.md
```

Observed:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
poll 1 feed.mode: inline
poll 2 feed.mode: inline
digest 1 item_count: 1
digest 2 item_count: 1
same event_id across repeated poll: true
source health: healthy
hero slot contains event: true
JP region lane contains event: true
event endpoint returns frozen event id: true
```

## Dedupe SQL

Storage-level dedupe verification used:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
```

Observed:

```text
queries 1-6: no rows
query 7:
  TDNET:4527:20260430:1900:140120260430515474:discovery-row row_count = 1
  TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474 row_count = 1
```

Additional storage checks:

```text
raw_events: 1
canonical_feed_items(event_id): 1
canonical_item_sources: 2
representative source count: 1
```

## Final locked contract values

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_family: material_information_update
canonical_event_type: material_information_update
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
```

## Final invariant values

```text
tdnet_raw_row_code: 45270
normalized_security_code: 4527
source_category: null
material_category: unknown
source_category_inferred: false
raw documents: discovery row + PDF attachment only
```

## Guardrails preserved

The close-out keeps these guardrails intact:

- broad JP all-disclosures ingestion remains out of scope
- TDnet live pagination remains out of scope
- additional TDnet rows remain out of scope
- EDINET runtime remains out of scope
- JPX Listed Company Search adapter remains out of scope
- title/category inference remains out of scope
- news overlay remains out of scope
- cross-source merge remains out of scope
- existing SEC, AFM, UK, TW, and CN locked runtimes are not changed
