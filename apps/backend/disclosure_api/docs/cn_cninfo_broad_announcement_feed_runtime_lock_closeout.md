# CNInfo broad announcement feed runtime lock close-out

This document closes out the controlled CNInfo broad announcement feed runtime lock.

## Runtime lock status

```text
cn_cninfo_broad_announcement_feed: locked
```

## Contract-freeze and implementation

```text
contract-freeze PR: #53
contract-freeze merge SHA: 8a3986ebdee936a20831af2a147d864fdb731e11
implementation PR: #55
implementation merge SHA: 0ef1dc0e26a57f84001626742d39f2926cd6ab67
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
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'; $env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_http_smoke_test.exs
```

Observed:

```text
cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
cn_cninfo_broad_announcement_feed_http_smoke_test.exs: PASS - 1 test, 0 failures
```

## Manual smoke

Manual smoke followed:

```text
apps/backend/disclosure_api/docs/cn_cninfo_broad_announcement_feed_manual_smoke.md
```

Observed:

```text
poll 1 records_seen: 3
poll 2 records_seen: 3
digest 1 item_count: 3
digest 2 item_count: 3
source health: healthy
cursor_key: latest_announcement_date_and_announcement_id_seen
region_code: cn for all items
home_market_region_code: cn for all items
date_only_cursor: true for all items
stable_external_id values:
  CNINFO:300376:20260501:1225274454
  CNINFO:603350:20260501:1225274838
  CNINFO:603660:20260501:1225274841
cursor_value values:
  2026-05-01|1225274454
  2026-05-01|1225274838
  2026-05-01|1225274841
```

Frozen event ids:

```text
cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838
cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454
```

## Dedupe SQL

Storage-level dedupe verification used:

```text
apps/backend/disclosure_api/priv/ops/cn_cninfo_broad_announcement_feed_dedupe_checks.sql
```

Observed:

```text
queries 1-6: no rows
query 7:
  CNINFO:300376:20260501:1225274454:discovery-row row_count = 1
  CNINFO:300376:20260501:1225274454:pdf:1225274454 row_count = 1
  CNINFO:603350:20260501:1225274838:discovery-row row_count = 1
  CNINFO:603350:20260501:1225274838:pdf:1225274838 row_count = 1
  CNINFO:603660:20260501:1225274841:discovery-row row_count = 1
  CNINFO:603660:20260501:1225274841:pdf:1225274841 row_count = 1
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

- locked `cn_cninfo_ownership_change` remains unchanged
- no unbounded CNInfo ingestion
- no CNInfo live pagination
- no additional CNInfo rows
- no SSE/SZSE/BSE separate adapters
- no EDINET runtime
- no news overlay
- no cross-source merge
- existing SEC, AFM, UK, TW, CN ownership-change, and JP locks remain preserved
