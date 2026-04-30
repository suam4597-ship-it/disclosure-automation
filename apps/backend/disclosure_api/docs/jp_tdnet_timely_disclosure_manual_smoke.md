# JP TDnet timely disclosure manual smoke

Manual smoke checklist for the isolated JP TDnet timely disclosure runtime slice.

## Frozen contract

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

## Start isolated server

From `apps/backend/disclosure_api`:

```bash
mix run priv/ops/run_jp_tdnet_timely_disclosure_server.exs
```

## Poll twice

```bash
curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_tdnet_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true'

curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_tdnet_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true'
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
event_id = jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
event_family = material_information_update
canonical_event_type = material_information_update
published_at_local = 2026-04-30T19:00:00+09:00
published_at_utc starts with 2026-04-30T10:00:00
filing_date_local = 2026-04-30
region_code = jp
home_market_region_code = jp
source_meta.stable_external_id = TDNET:4527:20260430:1900:140120260430515474
source_meta.cursor_key = latest_disclosure_datetime_security_code_and_pdf_token_seen
source_meta.cursor_value = 2026-04-30T19:00:00+09:00|4527|140120260430515474
source_meta.tdnet_raw_row_code = 45270
source_meta.normalized_security_code = 4527
source_meta.pdf_document_token = 140120260430515474
source_meta.source_category = null
source_meta.material_category = unknown
source_meta.source_category_inferred = false
```

## Check event

```bash
curl -s 'http://127.0.0.1:4000/api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474'
```

Expected:

```text
data.event_id matches frozen event id
data.event_family = material_information_update
data.canonical_event_type = material_information_update
```

## Check source health

```bash
curl -s 'http://127.0.0.1:4000/api/admin/source-health/jp_tdnet_timely_disclosure'
```

Expected:

```text
data.health_status = healthy
cursor key/value present
```

## Run dedupe SQL

Run:

```text
priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
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
- raw row code `45270` and normalized security code `4527` are both preserved
- source category remains null/unknown and is not inferred from title text
- dedupe SQL is clean
