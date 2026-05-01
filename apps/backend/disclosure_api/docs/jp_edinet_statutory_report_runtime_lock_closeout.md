# JP EDINET statutory report runtime lock close-out

This document closes out the isolated JP EDINET statutory report runtime lock for the single frozen `S100XZXO` fixture item.

## Runtime lock status

```text
jp_edinet_statutory_report: locked
```

## Implementation

```text
implementation PR: #60
implementation merge SHA: aa408b259a6e68039ec019cef1000eb6323f3b56
verification branch: chatgpt-jp-edinet-runtime-lock-closeout-v1
verification base: sec-thin-slice-reconcile-v1 at aa408b259a6e68039ec019cef1000eb6323f3b56
```

## Verification result

```text
automated runtime idempotency test: PASS
automated HTTP smoke test: PASS
regional regression tests: PASS
manual isolated smoke: PASS
storage-level dedupe SQL: PASS
API key redaction check: PASS
runtime code patch required after verification: no
runtime lock status: locked
```

## Test commands

Run from `apps/backend/disclosure_api`:

```powershell
$env:POSTGRES_USER='postgres'; $env:POSTGRES_PASSWORD='4597'; $env:POSTGRES_HOST='localhost'; $env:POSTGRES_DB='disclosure_automation_dev'; $env:POSTGRES_TEST_DB='disclosure_automation_test'
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_ownership_change_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_http_smoke_test.exs
```

Observed:

```text
all 10 test files: PASS
each file: 1 test, 0 failures
```

## Manual smoke

Manual smoke followed:

```text
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_manual_smoke.md
```

Observed:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
digest 1 item_count: 1
digest 2 item_count: 1
same event_id across repeated poll: true
source health: healthy
source health cursor location: data.cursors[0]
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
api_key_redacted: true
all request shapes use Subscription-Key=<redacted>
no real API key appears in persisted repo content
```

## Final locked contract

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
event_family: statutory_report_update
canonical_event_type: extraordinary_report
stable_external_id: EDINET:S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
published_at_local: 2026-04-30T09:00:00+09:00
published_at_utc: 2026-04-30T00:00:00.000000Z
filing_date_local: 2026-04-30
doc_id: S100XZXO
edinet_code: E12460
doc_type_code: 180
api_key_redacted: true
```

## Dedupe SQL

Storage-level dedupe verification used:

```text
apps/backend/disclosure_api/priv/ops/jp_edinet_statutory_report_dedupe_checks.sql
```

Observed:

```text
queries 1-6: no rows
query 7:
  EDINET:S100XZXO:document-list-row row_count = 1
  EDINET:S100XZXO:primary-document:type1 row_count = 1
```

Additional storage checks:

```text
raw_events: 1
canonical_feed_items(event_id): 1
raw_documents: 2
canonical_item_sources: 2
representative source count: 1
```

## API key redaction

Redaction check:

```powershell
git grep -n "Subscription-Key=" -- apps/backend/disclosure_api | Select-String -NotMatch '<redacted>'
```

Observed:

```text
PASS - all Subscription-Key= occurrences are Subscription-Key=<redacted>
```

## Guardrails preserved

- no EDINET API key committed
- all request shapes use `Subscription-Key=<redacted>`
- no EDINET broad pagination
- no multiple EDINET documents
- no TDnet changes
- no CNInfo changes
- no news overlay
- no cross-source merge
- existing locked regional runtimes preserved
