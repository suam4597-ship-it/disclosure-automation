# JP TDnet broad timely disclosure manual smoke

Manual smoke checklist for the controlled JP TDnet broad timely disclosure runtime slice.

## Frozen contract

```text
source_key: jp_tdnet_broad_timely_disclosure
adapter_key: jp_tdnet_broad_timely_disclosure_v1
sample_count: 3
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
```

Expected event ids:

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256
jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945
```

## Start isolated server

From `apps/backend/disclosure_api`:

```bash
mix run priv/ops/run_jp_tdnet_broad_timely_disclosure_server.exs
```

## Poll twice

```bash
curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_tdnet_broad_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true'

curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/jp_tdnet_broad_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true'
```

Expected both times:

```text
records_seen = 3
feed.mode = inline
```

## Check digest

```bash
curl -s 'http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking'
```

Expected:

```text
item_count = 3
all three frozen event ids are present
event_family = material_information_update for all items
canonical_event_type = material_information_update for all items
region_code = jp
source_category = null
material_category = unknown
source_category_inferred = false
```

## Check dedupe SQL

Run:

```text
priv/ops/jp_tdnet_broad_timely_disclosure_dedupe_checks.sql
```

Expected:

```text
queries 1-6 return no rows
query 7 returns row_count = 1 for all six frozen raw document external ids
```

## Pass condition

Manual smoke passes only if:

- poll 1 and poll 2 return `records_seen = 3`
- latest digest keeps three items and the three frozen event ids
- source health is healthy
- raw row code and normalized security code are both preserved for all rows
- source category remains null/unknown and is not inferred from title text
- dedupe SQL is clean
