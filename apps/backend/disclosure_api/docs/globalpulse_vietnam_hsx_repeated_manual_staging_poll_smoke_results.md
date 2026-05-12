# GlobalPulse Vietnam HSX Repeated Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records a second Fly staging manual live-poll smoke for the inactive Vietnam HSX listed-company news RSS candidate.

This is documentation-only. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HSX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HSX_LISTED_COMPANY_NEWS_RSS_CONFIRMED
VIETNAM_HSX_LISTED_COMPANY_NEWS_SOURCE_REGISTERED_INACTIVE
VIETNAM_HSX_REPEATED_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HSX_DIGEST_VISIBLE_LIVE
VIETNAM_HSX_LIVE_FIXTURE_FALLBACK_FALSE
VIETNAM_HSX_DETAIL_FETCH_DISABLED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Deployment Under Test

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
latest docs baseline: 4b257dc076d7e4ae96bf748eaed641f3d25ac11d
Fly app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
```

The latest docs-only merge commit CI was checked before this record:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
```

Observed:

```text
status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Manual Live Poll

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/vn_hsx_listed_company_news/poll?use_live_fetch=true&edition=breaking
```

Observed:

```text
source_key: vn_hsx_listed_company_news
edition: breaking
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 5972
records_seen: 10
records_inserted: 10
canonical_items count: 10
raw_documents count: 10
first_canonical: breaking-2026-05-11-2460982
```

## Source Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/vn_hsx_listed_company_news
```

Observed:

```text
health_status: healthy
active: false
config.candidate_status: manual_staging_only
config.disable_live_fixture_fallback: true
config.max_items_per_poll: 25
last_success_at: 2026-05-11T05:47:46.264253Z
last_seen_published_at: 2026-05-11T04:24:50.000000Z
last_error: null
```

## Digest Verification

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

Observed:

```text
digest_date: 2026-05-11
generated_at: 2026-05-11T05:47:47Z
item_count: 12
hsx_item_count: 2
metadata.fallback_to_fixture: false
```

Observed first HSX digest item:

```text
story_key: breaking-2026-05-11-2460982
headline: FUCTVGF5: Bao cao hoat dong dau tu thang 04/2026
source.source_key: vn_hsx_listed_company_news
metadata.fetch_mode: live
```

The original live headline contains Vietnamese diacritics. This document records the ASCII-normalized headline text for durable docs compatibility.

## Repeated Evidence Comparison

```text
first smoke records_seen: 10
repeated smoke records_seen: 10
first smoke digest hsx_item_count: 2
repeated smoke digest hsx_item_count: 2
first smoke fetch.mode: live
repeated smoke fetch.mode: live
first smoke metadata.fallback_to_fixture: false
repeated smoke metadata.fallback_to_fixture: false
```

Interpretation:

```text
HSX official RSS remained reachable from Fly staging.
The bounded rss_v1 parser continued to parse 10 listed-company news items.
The inactive/manual-staging-only source remained visible in the latest digest without fixture fallback.
No detail pages or attachments were fetched.
```

## Guardrails Confirmed

```text
source remains active=false
candidate_status remains manual_staging_only
disable_live_fixture_fallback remains true
fetch.mode is live
metadata.fallback_to_fixture is false
public digest JSON shape unchanged
production scheduled polling not enabled
public poll UI not added
audit UI not added
public Source Health UI not added
detail fetch not enabled
attachment fetch not enabled
```

## Next Allowed Steps

```text
1. Continue APAC official-source scanning within official exchange/OAM surfaces.
2. Keep observing India NSE scheduled staging runs until the 7-day window matures.
3. Revisit Taiwan MOPS only through another explicit staging-only cadence design or manual observation.
4. Keep KR deferred until the dedicated KR backend/source authority path exists.
5. Keep JP blocked until issue #339 source authority is resolved.
```
