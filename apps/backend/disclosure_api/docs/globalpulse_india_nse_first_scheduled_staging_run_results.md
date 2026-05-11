# GlobalPulse India NSE First Scheduled Staging Run Results

This document records the first automated scheduled staging run for the inactive India NSE announcements candidate.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, workflow schedule changes, source activation, or production scheduled live polling.

## Conclusion

```text
INDIA_NSE_FIRST_AUTOMATED_STAGING_SCHEDULE_RUN_PASS
INDIA_NSE_SCHEDULE_CRON_37_EVERY_2H_WEEKDAY_CONFIRMED
INDIA_NSE_SCHEDULED_RUN_FETCH_MODE_LIVE
INDIA_NSE_SCHEDULED_RUN_FIXTURE_FALLBACK_FALSE
INDIA_NSE_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Baseline

```text
workflow: GlobalPulse live staging poll
workflow run id: 25650796284
workflow run event: schedule
workflow run branch: main
workflow run head sha: 8445ae20f87432f58602482dcea772e994702a6c
workflow run status: completed
workflow run conclusion: success
created_at: 2026-05-11T04:45:25Z
updated_at: 2026-05-11T04:45:38Z
job: poll
job id: 75288522790
job conclusion: success
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
artifact name: globalpulse-live-staging-poll-25650796284
artifact id: 6910516526
artifact size: 3742 bytes
artifact digest: sha256:3a2a778dcb90d93d97d394f41e3c9f5eabc3df4bac0ebd54ed1afbc829715a8f
artifact URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25650796284/artifacts/6910516526
```

## Schedule Resolution

The workflow resolved the GitHub scheduled event to the India NSE source:

```text
SCHEDULE_EXPR: 37 */2 * * 1-5
SOURCE_KEY: india_nse_announcements
RUN_MODE: single_source
edition: breaking
```

This confirms the default-branch staging schedule registered by the India NSE workflow PR is active and routing to the intended inactive/manual-staging source.

## Health Evidence

```text
GET /api/health
health status: 200
status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Poll Evidence

```text
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking
poll status: 202
source_key: india_nse_announcements
edition: breaking
records_seen: 13
records_inserted: 13
canonical_items count: 13
raw_documents count: 13
fetch.loaded: true
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 56067
fetch.url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
```

Representative first canonical item:

```text
breaking-2026-05-11-https-nsearchives-nseindia-com-corporate-mahseamles-11052026101444-msliepfnewspaper-pdf
```

## Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking
digest status: 200
digest_date: 2026-05-11
edition: breaking
generated_at: 2026-05-11T04:45:35Z
generated_by: repo
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

Representative India NSE digest item:

```text
source_key: india_nse_announcements
display_name: India NSE Announcements
headline: Maharashtra Seamless Limited
canonical_url: https://nsearchives.nseindia.com/corporate/MAHSEAMLES_11052026101444_MSLIEPFNewspaper.pdf
published_at: 2026-05-11T10:14:55.000000Z
regions: india
metadata.fetch_mode: live
metadata.source_type: rss
story_key: breaking-2026-05-11-https-nsearchives-nseindia-com-corporate-mahseamles-11052026101444-msliepfnewspaper-pdf
```

The digest remained bounded to the existing public shape and included live India NSE items without fixture fallback.

## Guardrails Preserved

```text
source active flag: false
candidate_status: manual_staging_only
production scheduled India NSE polling: not enabled
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source: still deferred until the dedicated backend/source authority path exists
```

## Warning Notes

GitHub Actions emitted an informational runner warning that `actions/upload-artifact@v4` is still running on Node.js 20. This did not affect the India NSE health, poll, digest, or artifact upload result.

## Next Gate

India NSE has now passed its first automated staging schedule run.

Before production scheduled polling can be considered, keep observing the conservative staging schedule:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs: 10
allowed failures: 0 unresolved parser/content-type failures
allowed fallback live claims: 0
```

The next India NSE record should be a scheduled staging observation summary after enough runs have accumulated.
