# CNInfo ownership-change manual smoke

## Start isolated server

```powershell
$env:POSTGRES_USER="postgres"
$env:POSTGRES_PASSWORD="4597"
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_DB="disclosure_automation_dev"

$env:MIX_ENV="dev"; mix.bat ecto.reset
mix.bat run --no-start priv/ops/run_cn_cninfo_ownership_change_server.exs
```

## Poll and inspect

```powershell
irm http://127.0.0.1:4000/api/health

$poll1 = irm -Method POST "http://127.0.0.1:4000/api/admin/sources/cn_cninfo_ownership_change/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
$poll1 | ConvertTo-Json -Depth 10

$digest1 = irm "http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking"
$digest1 | ConvertTo-Json -Depth 10

$poll2 = irm -Method POST "http://127.0.0.1:4000/api/admin/sources/cn_cninfo_ownership_change/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
$poll2 | ConvertTo-Json -Depth 10

$digest2 = irm "http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking"
$digest2 | ConvertTo-Json -Depth 10

$digest1.items[0].event_id
$digest2.items[0].event_id
$digest1.items[0].event_family
$digest1.items[0].canonical_event_type
$digest1.items[0].source_meta.cursor_value
$digest1.items[0].source_meta.stable_external_id
```

## Pass condition

- both polls report `records_seen = 1`
- both digests report `item_count = 1`
- both digests keep the same `event_id`
- event id stays `cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497`
- event family stays `ownership_change_update`
- canonical event type stays `major_shareholding_or_insider_trade`
- cursor stays `2026-03-30|1225049497`
- stable external id stays `CNINFO:1225049497`
- source health is `healthy`
