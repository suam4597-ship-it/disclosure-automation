# TW MOPS material information minimal verification

## Test gate

```powershell
$env:MIX_ENV="test"; mix.bat test test/tw_mops_material_information_runtime_idempotency_test.exs
$env:MIX_ENV="test"; mix.bat test test/tw_mops_material_information_http_smoke_test.exs
```

## Expected assertions

- `records_seen == 1`
- digest `item_count == 1`
- `region_code == "tw"`
- `home_market_region_code == "tw"`
- `event_family == "material_information_update"`
- `canonical_event_type == "major_investment_or_asset_sale"`
- repeated poll keeps the same `event_id`
- source health becomes `healthy`
- cursor key is `latest_spoke_date_time_and_sequence_seen`

## Expected v0 exact values

- `event_id`: `tw.mops.2330.20260430.major_investment_or_asset_sale.material_information_update.1`
- `published_at_local`: `2026-04-30T16:29:38+08:00`
- `published_at_utc`: starts with `2026-04-30T08:29:38`
- `filing_date_local`: `2026-04-30`
- stable external id: `MOPS:2330:20260430:162938:1`
- cursor: `20260430|162938|2330|1`
- skey metadata: `2330202604301`
- ROC date metadata: `115/04/30`

## Dedupe SQL

Run:

```text
priv/ops/tw_mops_material_information_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns two rows with `row_count = 1`
