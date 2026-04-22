# SEC SC 13D/A manual smoke

Use this checklist after the SC 13D/A isolated runtime patch is in place.

## Base endpoint
- http://127.0.0.1:4000

## Prerequisite
Run the dedicated SC 13D/A dev server runner so startup bootstrap also uses the isolated SC 13D/A sample.

### PowerShell
1. `$env:POSTGRES_USER="postgres"`
2. `$env:POSTGRES_PASSWORD="<your-password>"`
3. `$env:MIX_ENV="dev"; mix.bat ecto.reset`
4. `mix.bat run --no-start priv/ops/run_sec_sc_13d_a_server.exs`

Keep that PowerShell window open while running the HTTP smoke sequence from a second window.

## Smoke sequence
1. GET /api/health
2. POST /api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true
3. GET /api/feed/hero
4. GET /api/feed/region/us
5. GET /api/feed/digest/latest?edition=breaking
6. Read the first item event_id from the digest response
7. GET /api/events/:event_id
8. GET /api/admin/source-health/sec_current_forms
9. Run the same poll again
10. GET /api/feed/digest/latest?edition=breaking again

## Expected results
- first poll returns success
- second poll also returns success
- latest digest item_count remains 1 after repeated poll
- event_id remains stable after repeated poll
- published_at_local remains 2026-03-10T09:42:18-05:00
- published_at_utc remains 2026-03-10T14:42:18Z
- filing_date_local remains 2026-03-10
- accepted_time_fallback remains false on the verified detail path
- fact_summary_ko does not contain SEC closing tags
- record the exact `event_family` and canonical event type from the first green run before tightening exact assertions

## Required follow-up
After the repeated poll, run priv/ops/sec_sc_13d_a_dedupe_checks.sql.
Do not move to later work until the SQL checks are clean.
