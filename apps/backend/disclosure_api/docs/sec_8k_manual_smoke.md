# SEC 8-K manual smoke

Use this checklist after the 8-K isolated runtime patch is in place.

## Base endpoint
- http://127.0.0.1:4000

## Prerequisite
Run the dedicated 8-K dev server runner so startup bootstrap also uses the isolated 8-K sample.

### PowerShell
1. `$env:MIX_ENV="dev"; mix run priv/ops/run_sec_8k_server.exs`

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
- published_at_local remains 2026-02-25T15:20:28-05:00
- published_at_utc remains 2026-02-25T20:20:28Z
- filing_date_local remains 2026-02-25
- accepted_time_fallback remains false on the verified detail path
- fact_summary_ko does not contain SEC closing tags

## Required follow-up
After the repeated poll, run priv/ops/sec_8k_dedupe_checks.sql.
No form expansion should start until the SQL checks are clean.
