# GlobalPulse Nasdaq Nordic Company News Staging Live Poll Smoke Results

This document records the staging live-poll and public UI smoke for the Nasdaq Nordic Company News candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Summary

```text
GLOBALPULSE_FLY_STAGING_DEPLOY_PASS
GLOBALPULSE_PUBLIC_PAGES_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
NASDAQ_NORDIC_COMPANY_NEWS_LIVE_POLL_PASS
NASDAQ_NORDIC_PUBLIC_UI_PASS
SCHEDULED_POLLING_DISABLED_EXPECTED
```

## Source

```text
source_key: eu_nasdaq_nordic_company_news
display_name: Nasdaq Nordic Company News
authority: Nasdaq Nordic official company-announcement surface
supporting URL: https://www.nasdaq.com/european-market-activity/news/company-news
machine-readable URL: https://api.news.eu.nasdaq.com/news/query.action
parser: nasdaq_nordic_cns_jsonp_v1
region: eu_north
UI label: Northern Europe
active: false
candidate_status: manual_staging_only
```

## Code And CI Basis

```text
candidate PR: #398 Add Nasdaq Nordic company news candidate
merge commit: fd36e0416105be8ebb31812b23ed6dbf7f2b1ec0
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
parser fixture smoke: 2 records
parser live JSONP smoke: 25 records
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
GET /api/admin/source-health/eu_nasdaq_nordic_company_news: 200
active: false
candidate_status: manual_staging_only
parser_key: nasdaq_nordic_cns_jsonp_v1
```

## Live Poll Smoke

Command:

```text
POST /api/admin/sources/eu_nasdaq_nordic_company_news/poll?edition=breaking
```

Result:

```text
HTTP: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 20382
records_seen: 25
records_inserted: 25
metadata.fallback_to_fixture: false
```

Representative canonical item:

```text
headline: Kaldalón hf.: Conditions for the acquisition of real estate from FÍ fasteignafélag fulfilled
source.display_name: Nasdaq Nordic Company News
source.source_key: eu_nasdaq_nordic_company_news
regions: eu_north
fetch_mode: live
```

Digest result:

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
Nasdaq Nordic item count in top digest: 1
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
Northern Europe region label: present
Nasdaq Nordic Company News source label: present
Nasdaq Nordic headline: present
```

Observed UI snippets:

```text
Backend ok
Northern Europe 1 items / avg 90
Northern Europe
Kaldalón hf.: Conditions for the acquisition of real estate from FÍ fasteignafélag fulfilled
Nasdaq Nordic company news | Category: Other information disclosed according to the rules of the Exchange | Market: Main Market, Iceland | Language: en | Attachments: 0
Nasdaq Nordic Company News
```

Browser notes:

```text
One generic 404 console message was observed from the static Pages surface.
No API, CORS, backend connectivity, or rendering blocker was observed.
```

## Guardrails

```text
scheduled Nasdaq Nordic live polling remains disabled
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
NASDAQ_NORDIC_COMPANY_NEWS_READY_FOR_BATCH_PROMOTION_DECISION
```

Nasdaq Nordic now has an official exchange company-announcement candidate with staging live-poll and public UI smoke passing. It should remain manual-only until the broader Europe listed-company disclosure source batch is intentionally promoted.
