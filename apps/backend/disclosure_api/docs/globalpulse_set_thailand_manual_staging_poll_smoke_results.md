# GlobalPulse SET Thailand Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records the manual Fly staging smoke for the inactive SET Thailand company-news source candidate.

This is a manual-staging-only result. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch SET detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
SET_THAILAND_MANUAL_STAGING_POLL_PASS
SET_THAILAND_LIVE_FETCH_FROM_FLY_STAGING_PASS
SET_THAILAND_RECORDS_SEEN_25
SET_THAILAND_RECORDS_INSERTED_25
SET_THAILAND_DIGEST_UPDATED_ITEM_COUNT_12
SET_THAILAND_FIXTURE_FALLBACK_FALSE
SET_THAILAND_SOURCE_REMAINS_INACTIVE
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Deployment Context

```text
base branch: phase0-foundation
deployed merge commit: e968d1079e8413d6fb5b5a1caefffd02a17cb7a1
deployed PR: #509 Add inactive SET Thailand parser source candidate
Fly app: globalpulse-backend-staging
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KRAJMWDZGXQ1842RV278MNBP
release command: DisclosureAutomation.Release.migrate()
release command result: success
```

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
```

Observed bounded body:

```json
{"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Manual Poll

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/th_set_company_news/poll?use_live_fetch=true&edition=breaking
status: 202
```

Observed bounded poll fields:

```text
source_key: th_set_company_news
edition: breaking
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 25405
fetch.url: https://www.set.or.th/api/cms/v1/news/set?sourceId=company&securityTypeIds=S&fromDate=11/05/2026&toDate=11/05/2026&orderBy=date&lang=en
records_seen: 25
records_inserted: 25
```

Observed canonical item examples:

```text
breaking-2026-05-11-set-thailand-17784560467780
breaking-2026-05-11-set-thailand-17784560467360
breaking-2026-05-11-set-thailand-17784560466740
breaking-2026-05-11-set-thailand-104057100
```

No fixture fallback was used by the poll response. The poll response reported `fetch.mode=live`.

## Digest Verification

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
```

Observed bounded digest fields:

```text
digest_date: 2026-05-11
edition: breaking
generated_at: 2026-05-11T03:55:07Z
generated_by: repo
item_count: 12
metadata.fallback_to_fixture: false
```

Observed first digest item:

```text
source.source_key: th_set_company_news
source.display_name: SET Thailand Company News
headline: BKA - Financial Statement Quarter 1/2026 (Reviewed)
metadata.fetch_mode: live
metadata.source_type: api
regions: asean
sectors: markets
```

## Safety Boundaries Confirmed

```text
source active=true: not enabled
production scheduled polling: not enabled
workflow schedule: not added
public poll UI: not added
public Source Health UI: not added
audit UI: not added
backend digest JSON shape: unchanged
detail/attachment fetch: not added
fixture fallback as live success: not observed
third-party mirrors or aggregators: not used
KR source path: still deferred
JP live polling: still blocked until source authority issue is resolved
```

## Next Step

SET has now passed the first manual staging live smoke. The safer next step is one more repeated manual smoke in a different observation window before any discussion of activation or scheduling.

Allowed next work:

```text
1. Repeat SET Thailand manual staging live smoke in another time window.
2. If repeated smoke passes, write a separate cadence/activation decision doc while still keeping active=false.
3. Continue APAC expansion with IDX Fly/Elixir runtime compatibility probe if SET repetition is delayed.
```
