# JP EDINET statutory report manual smoke

Manual smoke checklist for the isolated JP EDINET statutory report runtime slice.

## Frozen contract

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
stable_external_id: EDINET:S100XZXO
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: 2026-04-30T09:00:00+09:00|S100XZXO
```

## Start isolated server

From `apps/backend/disclosure_api`:

```bash
mix run priv/ops/run_jp_edinet_statutory_report_server.exs
```

## Poll twice

```bash
curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_edinet_statutory_report/poll?edition=breaking&use_live_fetch=false&inline_feed=true'

curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_edinet_statutory_report/poll?edition=breaking&use_live_fetch=false&inline_feed=true'
```

Expected both times:

```text
records_seen = 1
feed.mode = inline
```

## Check digest

```bash
curl -s 'http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking'
```

Expected:

```text
item_count = 1
event_id = jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
event_family = statutory_report_update
canonical_event_type = extraordinary_report
published_at_local = 2026-04-30T09:00:00+09:00
published_at_utc starts with 2026-04-30T00:00:00
filing_date_local = 2026-04-30
region_code = jp
source_meta.stable_external_id = EDINET:S100XZXO
source_meta.cursor_key = latest_submit_datetime_and_doc_id_seen
source_meta.cursor_value = 2026-04-30T09:00:00+09:00|S100XZXO
source_meta.doc_id = S100XZXO
source_meta.edinet_code = E12460
source_meta.doc_type_code = 180
source_meta.api_key_redacted = true
```

## API key redaction check

Expected:

```text
all request shapes use Subscription-Key=<redacted>
no actual API key appears in response JSON, raw docs, or source metadata
```

## Check event

```bash
curl -s 'http://127.0.0.1:4000/api/events/jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO'
```

Expected:

```text
data.event_id matches frozen event id
data.event_family = statutory_report_update
data.canonical_event_type = extraordinary_report
```

## Check source health

```bash
curl -s 'http://127.0.0.1:4000/api/admin/source-health/jp_edinet_statutory_report'
```

Expected:

```text
data.health_status = healthy
cursor key/value present
```

## Run dedupe SQL

Run:

```text
priv/ops/jp_edinet_statutory_report_dedupe_checks.sql
```

Expected:

```text
queries 1-6 return no rows
query 7 returns exactly one row for each frozen raw document external id
```

## Pass condition

Manual smoke passes only if:

- poll 1 and poll 2 return `records_seen = 1`
- latest digest keeps one item and the frozen event id
- event endpoint returns the frozen event id
- JP region lane includes the item
- source health is healthy
- API key remains redacted everywhere
- dedupe SQL is clean
