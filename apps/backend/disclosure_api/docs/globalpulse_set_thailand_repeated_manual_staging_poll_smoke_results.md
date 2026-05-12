# GlobalPulse SET Thailand Repeated Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records the repeated observation-window Fly staging smoke for the inactive SET Thailand company-news source candidate.

This is a manual-staging-only result. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch SET detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
SET_THAILAND_REPEATED_MANUAL_STAGING_POLL_PASS
SET_THAILAND_SECOND_LIVE_FETCH_FROM_FLY_STAGING_PASS
SET_THAILAND_RECORDS_SEEN_25
SET_THAILAND_RECORDS_INSERTED_25
SET_THAILAND_DIGEST_VISIBLE_ITEM_COUNT_6
SET_THAILAND_FIXTURE_FALLBACK_FALSE
SET_THAILAND_SOURCE_REMAINS_INACTIVE
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Deployment Context

The repeated smoke used the currently deployed Fly staging backend:

```text
Fly app: globalpulse-backend-staging
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KRAMCZFXH1W8W85XAZM7FA0W
runtime source candidate: th_set_company_news
candidate status: manual_staging_only
source active: false
```

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
body.status: ok
body.service: disclosure_automation
body.phase: phase1
body.repo: up
```

## Repeated Manual Poll

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/th_set_company_news/poll?use_live_fetch=true&edition=breaking
status: 202
source_key: th_set_company_news
edition: breaking
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 25469
fetch.url: https://www.set.or.th/api/cms/v1/news/set?sourceId=company&securityTypeIds=S&fromDate=11/05/2026&toDate=11/05/2026&orderBy=date&lang=en
records_seen: 25
records_inserted: 25
first_canonical_item: breaking-2026-05-11-set-thailand-17784560467780
last_canonical_item_in_batch: breaking-2026-05-11-set-thailand-104055600
raw_documents: 25
```

## Source Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/th_set_company_news
status: 200
source.active: false
source.health_status: healthy
source.last_success_at: 2026-05-11T04:28:30.703387Z
source.last_seen_published_at: 2026-05-11T02:11:51.000000Z
source.last_error: null
source.config.candidate_status: manual_staging_only
source.config.disable_live_fixture_fallback: true
```

## Digest Verification

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
edition: breaking
digest_date: 2026-05-11
generated_at: 2026-05-11T04:28:44Z
item_count: 12
set_item_count: 6
hnx_item_count: 6
first_set_source_key: th_set_company_news
first_set_fetch_mode: live
metadata.fallback_to_fixture: false
```

Representative first SET headline:

```text
BKA - Financial Statement Quarter 1/2026 (Reviewed)
```

## Boundary Confirmation

```text
source remains active=false
candidate_status remains manual_staging_only
fixture fallback remains disabled for live smoke
detail fetch not added
attachment fetch not added
workflow not added
scheduled polling not enabled
public poll UI not added
audit UI not added
public Source Health UI not added
backend digest JSON shape unchanged
KR remains deferred
JP remains blocked by issue #339
```

## Current Decision

```text
SET now has repeated manual Fly staging live-poll evidence.
Keep the source inactive.
Do not enable ASEAN or APAC production scheduled polling.
Any future schedule discussion should be staging-only first and must stay bounded.
```
