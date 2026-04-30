# CNInfo ownership-change minimal verification

## Test gate

```powershell
$env:MIX_ENV="test"; mix.bat test test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
$env:MIX_ENV="test"; mix.bat test test/cn_cninfo_ownership_change_http_smoke_test.exs
```

## Expected assertions

- `records_seen == 1`
- digest `item_count == 1`
- `region_code == "cn"`
- `home_market_region_code == "cn"`
- `event_family == "ownership_change_update"`
- `canonical_event_type == "major_shareholding_or_insider_trade"`
- repeated poll keeps the same `event_id`
- source health becomes `healthy`
- cursor key is `latest_announcement_date_and_announcement_id_seen`

## Expected v0 exact values

- `event_id`: `cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497`
- `published_at_local`: `2026-03-30T00:00:00+08:00`
- `published_at_utc`: starts with `2026-03-29T16:00:00`
- `filing_date_local`: `2026-03-30`
- stable external id: `CNINFO:1225049497`
- cursor: `2026-03-30|1225049497`
- security code: `000404`
- security short name: `长虹华意`
- date-only cursor flag: `true`

## Dedupe SQL

Run:

```text
priv/ops/cn_cninfo_ownership_change_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns two rows with `row_count = 1`
