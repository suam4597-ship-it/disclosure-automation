# JP TDnet broad timely disclosure runtime lock close-out

This document closes out the controlled JP TDnet broad timely disclosure runtime lock.

## Runtime lock status

```text
jp_tdnet_broad_timely_disclosure: locked
```

## Contract-freeze and implementation

```text
contract-freeze PR: #52
contract-freeze merge SHA: b01ebc01e5698ae619482c264f8f952d6fb6bf9e
implementation PR: #54
implementation merge SHA: 8b950925ad0a10e65a4e406941caaeac9c490554
verification branch: chatgpt-broad-runtime-lock-closeout-v1
verification base: sec-thin-slice-reconcile-v1 at df8073ca054bfeea4c451308d381023736ecc804
```

## Verification result

```text
automated runtime idempotency test: PASS
automated HTTP smoke test: PASS
manual isolated smoke: PASS
storage-level dedupe SQL: PASS
code patch required after verification: no
runtime lock status: locked
```

## Test commands

```powershell
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_http_smoke_test.exs
```

Observed:

```text
jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
jp_tdnet_broad_timely_disclosure_http_smoke_test.exs: PASS - 1 test, 0 failures
```

## Manual smoke

Manual smoke followed:

```text
apps/backend/disclosure_api/docs/jp_tdnet_broad_timely_disclosure_manual_smoke.md
```

Observed:

```text
poll 1 records_seen: 3
poll 2 records_seen: 3
digest 1 item_count: 3
digest 2 item_count: 3
source health: healthy
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
event_family: material_information_update for all items
canonical_event_type: material_information_update for all items
region_code: jp for all items
source_category: null for all items
material_category: unknown for all items
source_category_inferred: false for all items
tdnet_raw_row_code values: 28710, 60880, 45270
normalized_security_code values: 2871, 6088, 4527
```

Frozen event ids:

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256
jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945
```

## Dedupe SQL

Storage-level dedupe verification used:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_broad_timely_disclosure_dedupe_checks.sql
```

Observed:

```text
queries 1-6: no rows
query 7:
  TDNET:2871:20260430:1700:140120260430515256:discovery-row row_count = 1
  TDNET:2871:20260430:1700:140120260430515256:pdf:140120260430515256 row_count = 1
  TDNET:4527:20260430:1900:140120260430515474:discovery-row row_count = 1
  TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474 row_count = 1
  TDNET:6088:20260430:1700:140120260430514945:discovery-row row_count = 1
  TDNET:6088:20260430:1700:140120260430514945:pdf:140120260430514945 row_count = 1
```

Additional storage checks:

```text
raw_events: 3
canonical_feed_items: 3
raw_documents: 6
canonical_item_sources: 6
representative source count: 3
```

## Guardrails preserved

- locked `jp_tdnet_timely_disclosure` remains unchanged
- no unbounded TDnet ingestion
- no TDnet live pagination
- no additional TDnet rows
- no EDINET runtime
- no JPX Listed Company Search adapter
- no title/category inference
- no news overlay
- no cross-source merge
- existing SEC, AFM, UK, TW, CN, and isolated JP locks remain preserved
