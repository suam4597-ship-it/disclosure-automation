# JP EDINET statutory report verification ledger

This ledger records runtime-lock verification for the isolated JP EDINET statutory report runtime slice.

## Scope

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
docID: S100XZXO
stable_external_id: EDINET:S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
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

## Automated tests

Run from `apps/backend/disclosure_api` with PostgreSQL env vars set.

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_http_smoke_test.exs
```

Observed:

```text
jp_edinet_statutory_report_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
jp_edinet_statutory_report_http_smoke_test.exs: PASS - 1 test, 0 failures
```

## Regional regression tests

```powershell
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
jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
jp_tdnet_timely_disclosure_http_smoke_test.exs: PASS - 1 test, 0 failures
jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
jp_tdnet_broad_timely_disclosure_http_smoke_test.exs: PASS - 1 test, 0 failures
cn_cninfo_ownership_change_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
cn_cninfo_ownership_change_http_smoke_test.exs: PASS - 1 test, 0 failures
cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs: PASS - 1 test, 0 failures
cn_cninfo_broad_announcement_feed_http_smoke_test.exs: PASS - 1 test, 0 failures
```

## Manual smoke

Manual smoke followed:

```text
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_manual_smoke.md
```

Observed:

```text
poll 1 records_seen: 1
poll 1 feed.mode: inline
poll 2 records_seen: 1
poll 2 feed.mode: inline
digest 1 item_count: 1
digest 2 item_count: 1
same event_id across repeated poll: true
event endpoint event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
source health: healthy
source health cursor location: data.cursors[0]
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
api_key_redacted: true
```

Observed canonical values:

```text
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
event_family: statutory_report_update
canonical_event_type: extraordinary_report
published_at_local: 2026-04-30T09:00:00+09:00
published_at_utc: 2026-04-30T00:00:00.000000Z
filing_date_local: 2026-04-30
stable_external_id: EDINET:S100XZXO
doc_id: S100XZXO
edinet_code: E12460
doc_type_code: 180
```

## Storage-level dedupe

Verification used the SQL from:

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

One docs-only secret-handling example was tightened so the persisted request shape remains `Subscription-Key=<redacted>` and the executable URL is assembled only in local shell memory.

## Guardrails preserved

- no EDINET API key committed
- all persisted request shapes use `Subscription-Key=<redacted>`
- no EDINET broad pagination
- no multiple EDINET documents
- no TDnet changes
- no CNInfo changes
- no news overlay
- no cross-source merge
- existing locked regional runtimes preserved
