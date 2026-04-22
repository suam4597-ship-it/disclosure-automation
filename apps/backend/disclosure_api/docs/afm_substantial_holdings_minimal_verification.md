# AFM substantial holdings minimal verification

## Test gate

```powershell
$env:MIX_ENV="test"; mix.bat test test/afm_substantial_holdings_runtime_idempotency_test.exs
$env:MIX_ENV="test"; mix.bat test test/afm_substantial_holdings_http_smoke_test.exs
```

## Expected assertions

- `records_seen == 1`
- digest `item_count == 1`
- `region_code == "nl"`
- `home_market_region_code == "nl"`
- `event_family == "shareholding_threshold_crossing"`
- `canonical_event_type == "major_shareholding_or_insider_trade"`
- repeated poll keeps the same `event_id`
- source health becomes `healthy`
- cursor key is `latest_notification_seen`

## Dedupe SQL

Run:

```text
priv/ops/afm_substantial_holdings_dedupe_checks.sql
```

Expected:

- queries 1-6 return no rows
- query 7 returns two rows with `row_count = 1`
