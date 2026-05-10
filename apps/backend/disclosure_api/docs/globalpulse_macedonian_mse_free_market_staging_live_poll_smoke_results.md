# GlobalPulse Macedonian MSE Free Market Staging Live Poll Smoke Results

## Summary

```text
GLOBALPULSE_MSE_FREE_MARKET_STAGING_LIVE_POLL_PASS
GLOBALPULSE_MSE_FREE_MARKET_SOURCE_HEALTH_PASS
GLOBALPULSE_MSE_FREE_MARKET_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
GLOBALPULSE_MSE_FREE_MARKET_LATEST_PUBLIC_UI_VISIBILITY_PENDING
GLOBALPULSE_MSE_FREE_MARKET_SCHEDULED_POLLING_DISABLED
```

## Scope

```text
source_key: mk_mse_free_market_announcements
owner: Macedonian Stock Exchange
candidate URL: https://www.mse.mk/Issuers.aspx
parser: mse_free_market_announcements_html_v1
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
deployed phase0-foundation commit: 009aa66a5cb366a47905f87d71b348f1e1822133
smoke date: 2026-05-10
```

## Fly Staging Deploy

```text
command: fly deploy --remote-only --app globalpulse-backend-staging
deploy result: success
release_command: success
app URL: https://globalpulse-backend-staging.fly.dev/
```

## Health Check

```text
GET /api/health
status: 200
body.status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Source Health

```text
GET /api/admin/source-health/mk_mse_free_market_announcements
status: 200
source_key: mk_mse_free_market_announcements
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
parser_key: mse_free_market_announcements_html_v1
health_status: healthy
last_error: null
last_failure_at: null
last_success_at: 2026-05-10T13:57:56.709116Z
last_seen_published_at: 2026-05-08T00:00:00.000000Z
```

## Live Poll

```text
POST /api/admin/sources/mk_mse_free_market_announcements/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 134203
records_seen: 25
records_inserted: 25
canonical_items_count: 22
raw_documents_count: 25
fixture_fallback: false
```

Observed canonical rows included date buckets:

```text
2026-05-08
2026-05-06
2026-05-05
2026-04-30
2026-04-29
2026-04-28
```

## Digest Visibility

```text
GET /api/feed/digest/2026-05-06/breaking
status: 200
mse_count: 1
region: eu_south
fetch_mode: live

GET /api/feed/digest/2026-05-05/breaking
status: 200
mse_count: 2
region: eu_south
fetch_mode: live
```

Latest public digest visibility remains pending:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
latest digest_date: 2026-05-09
latest digest item_count: 12
MSE latest row date: 2026-05-08
result: latest public UI visibility pending due current latest digest date/top-N selection
```

## Guardrails

```text
scheduled polling: disabled
source active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
backend digest JSON response shape: unchanged
public poll UI: not added
public Source Health UI: not added
audit UI: not added
frontend framework: not added
```

## Conclusion

```text
Macedonian Stock Exchange Free Market Announcements is a proven inactive/manual_staging_only staging live candidate.
It should remain out of scheduled polling until the broader Europe source batch promotion decision is made.
```
