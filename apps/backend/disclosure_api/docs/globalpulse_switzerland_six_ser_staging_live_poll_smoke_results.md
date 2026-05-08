# GlobalPulse Switzerland SIX SER Staging Live Poll Smoke Results

This document records the staging live-poll and public UI smoke for the Switzerland SIX Exchange Regulation official-notices candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Summary

```text
GLOBALPULSE_FLY_STAGING_DEPLOY_PASS
GLOBALPULSE_PUBLIC_PAGES_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
SWITZERLAND_SIX_SER_OFFICIAL_NOTICES_LIVE_POLL_PASS
SWITZERLAND_SIX_SER_PUBLIC_UI_PASS
SCHEDULED_POLLING_DISABLED_EXPECTED
```

## Source

```text
source_key: ch_six_ser_official_notices
display_name: Switzerland SIX SER Official Notices
authority: SIX Exchange Regulation / SER official notices
supporting URL: https://www.six-group.com/en/market-data/news-tools/official-notices.html
machine-readable URL: https://www.ser-ag.com/itf-data/official-notices/rss-en.xml
parser: rss_v1
region: ch
UI label: Switzerland
active: false
candidate_status: manual_staging_only
```

## Code And CI Basis

```text
candidate PR: #396 Add Switzerland SIX SER official notices candidate
merge commit: e79e781a35e005eb3fcbddcb7c09dfd8b1be1d42
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

Local validation before merge:

```text
MIX_ENV=test mix deps.get
MIX_ENV=test mix format lib/disclosure_automation/pipeline.ex
MIX_ENV=test mix compile --warnings-as-errors --force
MIX_ENV=test mix compile --warnings-as-errors --force
node --check apps/web/config.js
parser fixture smoke: 2 records
parser live RSS smoke: 25 records
```

Note:

```text
The first dependency build emitted existing Phoenix dependency typing warnings while still exiting 0.
The second forced compile was clean.
```

## Fly Staging Deploy

```text
app: globalpulse-backend-staging
deploy command: fly deploy --remote-only --app globalpulse-backend-staging
deploy: success
release_command: success
backend URL: https://globalpulse-backend-staging.fly.dev
GET /api/health: 200
health_status: ok
```

Source registry after deploy:

```text
GET /api/admin/source-health/ch_six_ser_official_notices: 200
active: false
candidate_status: manual_staging_only
parser_key: rss_v1
health_status: healthy
last_seen_published_at: 2026-05-08T18:00:30.000000Z
```

## Live Poll Smoke

Command:

```text
POST /api/admin/sources/ch_six_ser_official_notices/poll?edition=breaking
```

Result:

```text
HTTP: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 65762
records_seen: 25
records_inserted: 25
metadata.fallback_to_fixture: false
```

Representative canonical item:

```text
headline: Increase/Decrease of issue size
summary: Zuercher Kantonalbank Finance (Guernsey) Ltd - Increase/Decrease of issue size
source.display_name: Switzerland SIX SER Official Notices
source.source_key: ch_six_ser_official_notices
regions: ch
published_at: 2026-05-08T18:00:30.000000Z
fetch_mode: live
```

Digest result:

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
Switzerland item count in top digest: 1
```

## Public Pages UI Smoke

URL:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Headless browser DOM result:

```text
title: GlobalPulse
Backend ok: present
Switzerland region label: present
Switzerland SIX SER Official Notices source label: present
Increase/Decrease of issue size headline: present
```

Observed UI snippets:

```text
Backend ok
Switzerland 1 items / avg 90
Switzerland
Increase/Decrease of issue size
Zuercher Kantonalbank Finance (Guernsey) Ltd - Increase/Decrease of issue size
Switzerland SIX SER Official Notices
```

Browser notes:

```text
One generic 404 console message was observed from the static Pages surface.
No API, CORS, backend connectivity, or rendering blocker was observed.
```

## Guardrails

```text
scheduled Switzerland live polling remains disabled
manual staging-only source remains active=false
no backend JSON response-shape change
no frontend framework added
no public poll UI added
no audit UI added
no public Source Health UI added
no provider/materializer/canonical behavior change
JP source authority remains blocked by issue #339 and was not changed
```

## Conclusion

```text
SWITZERLAND_SIX_SER_OFFICIAL_NOTICES_READY_FOR_BATCH_PROMOTION_DECISION
```

Switzerland now has an official exchange-regulation RSS candidate with staging live-poll and public UI smoke passing. It should remain manual-only until the broader Europe listed-company disclosure source batch is intentionally promoted.
