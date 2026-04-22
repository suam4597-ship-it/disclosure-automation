# AFM substantial holdings manual smoke

## Start isolated server

```powershell
$env:POSTGRES_USER="postgres"
$env:POSTGRES_PASSWORD="4597"
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_DB="disclosure_automation_dev"

$env:MIX_ENV="dev"; mix.bat ecto.reset
mix.bat run --no-start priv/ops/run_afm_substantial_holdings_server.exs
```

## Poll and inspect

```powershell
irm http://127.0.0.1:4000/api/health

$poll1 = irm -Method POST "http://127.0.0.1:4000/api/admin/sources/afm_substantial_holdings/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
$poll1 | ConvertTo-Json -Depth 10

$digest1 = irm "http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking"
$digest1 | ConvertTo-Json -Depth 10

$poll2 = irm -Method POST "http://127.0.0.1:4000/api/admin/sources/afm_substantial_holdings/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
$poll2 | ConvertTo-Json -Depth 10

$digest2 = irm "http://127.0.0.1:4000/api/feed/digest/latest?edition=breaking"
$digest2 | ConvertTo-Json -Depth 10

$digest1.items[0].event_id
$digest2.items[0].event_id
$digest1.items[0].event_family
$digest1.items[0].canonical_event_type
```

## Pass condition

- both polls report `records_seen = 1`
- both digests report `item_count = 1`
- both digests keep the same `event_id`
