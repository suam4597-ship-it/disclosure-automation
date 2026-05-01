# CNInfo broad announcement feed manual smoke

Manual smoke checklist for the controlled CNInfo broad announcement feed runtime slice.

## Frozen contract

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
sample_count: 3
cursor_key: latest_announcement_date_and_announcement_id_seen
```

Expected event ids:

```text
cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838
cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454
```

## Start isolated server

From `apps/backend/disclosure_api`:

```bash
mix run priv/ops/run_cn_cninfo_broad_announcement_feed_server.exs
```

## Poll twice

```bash
curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/cn_cninfo_broad_announcement_feed/poll?edition=breaking&use_live_fetch=false&inline_feed=true'

curl -s -X POST 'http://127.0.0.1:4000/api/admin/sources/cn_cninfo_broad_announcement_feed/poll?edition=breaking&use_live_fetch=false&inline_feed=true'
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
region_code = cn
home_market_region_code = cn
date_only_cursor = true
```

## Check dedupe SQL

Run:

```text
priv/ops/cn_cninfo_broad_announcement_feed_dedupe_checks.sql
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
- all three stable external ids are present
- dedupe SQL is clean
