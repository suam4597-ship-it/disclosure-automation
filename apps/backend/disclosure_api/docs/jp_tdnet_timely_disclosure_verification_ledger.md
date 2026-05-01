# JP TDnet timely disclosure verification ledger

This ledger records actual verification output for the JP TDnet timely disclosure runtime slice.

## Runtime slice

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
```

## Current verification state

```text
automated runtime idempotency test: PASS
automated HTTP smoke test: PASS
manual isolated smoke: PASS
storage-level dedupe SQL: PASS
code patch required after verification: yes
runtime lock status: locked
```

## Automated tests

### Runtime idempotency test

Command:

```powershell
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
```

Result:

```text
PASS - 1 test, 0 failures
```

Notes:

```text
Initial run failed on source_registry_source_type_check because the JP TDnet sample used source_type public_web. The close-out branch changes that isolated sample registry value to api, matching the existing source_registry enum and other official regulatory fixture sources.
```

### HTTP smoke test

Command:

```powershell
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Result:

```text
PASS - 1 test, 0 failures
```

Notes:

```text
Final run passed after the isolated source registry sample source_type patch.
```

## Manual isolated smoke

Source document:

```text
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_manual_smoke.md
```

Observed values:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
poll 1 feed.mode: inline
poll 2 feed.mode: inline
digest 1 item_count: 1
digest 2 item_count: 1
same event_id across repeated poll: true
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
event_family: material_information_update
canonical_event_type: material_information_update
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
source health: healthy
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
tdnet_raw_row_code: 45270
normalized_security_code: 4527
source_category: null
material_category: unknown
source_category_inferred: false
hero slot contains event: true
JP region lane contains event: true
event endpoint returns frozen event id: true
```

Result:

```text
PASS
```

## Storage-level dedupe SQL

SQL file:

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

Result:

```text
PASS
```

## Contract invariants re-checked

- [x] event id exactly matches frozen event id
- [x] stable external id exactly matches frozen stable external id
- [x] cursor key/value exactly match frozen cursor
- [x] raw TDnet row code `45270` is preserved
- [x] normalized security code `4527` is preserved
- [x] source category remains `null`
- [x] material category remains `unknown`
- [x] `source_category_inferred` remains `false`
- [x] raw documents are exactly discovery row plus PDF attachment
- [x] canonical item source count is 2
- [x] representative canonical item source count is 1

## Close-out decision

```text
locked
```

The JP TDnet timely disclosure runtime slice is locked after automated tests, manual isolated smoke, and storage-level dedupe verification all passed on the close-out branch.
