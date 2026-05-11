# GlobalPulse Vietnam HSX Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records the first Fly staging manual live-poll smoke for the inactive Vietnam HSX listed-company news RSS candidate.

This is documentation-only. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HSX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HSX_LISTED_COMPANY_NEWS_RSS_CONFIRMED
VIETNAM_HSX_LISTED_COMPANY_NEWS_SOURCE_REGISTERED_INACTIVE
VIETNAM_HSX_MANUAL_STAGING_SMOKE_PASS
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
merge commit: cf0bc4aac18beb97ecc3e58b1239043b25e058e9
PR: #517 Add inactive Vietnam HSX listed company RSS candidate
Fly app: globalpulse-backend-staging
deployed image: registry.fly.io/globalpulse-backend-staging:deployment-01KRANX01CREM0P4QZWHQV5HWN
```

The #517 merge commit CI was checked before deployment:

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
canonical_items:
  - breaking-2026-05-11-2460982
  - breaking-2026-05-11-2460981
  - breaking-2026-05-11-2460980
  - breaking-2026-05-11-2460979
  - breaking-2026-05-11-2460978
  - breaking-2026-05-11-2460977
  - breaking-2026-05-11-2460976
  - breaking-2026-05-11-2460975
  - breaking-2026-05-11-2460822
  - breaking-2026-05-11-2460838
```

A follow-up full JSON inspection repeated the bounded manual poll and returned the same live endpoint, status code, record count, and canonical item set. This was a manual staging confirmation only, not scheduled polling.

## Source Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/vn_hsx_listed_company_news
```

Observed:

```text
health_status: healthy
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
last_success_at: 2026-05-11T04:52:07.496432Z
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
generated_at: 2026-05-11T04:52:23Z
item_count: 12
hsx_item_count: 2
metadata.fallback_to_fixture: false
```

Observed HSX digest items:

```text
story_key: breaking-2026-05-11-2460982
headline: FUCTVGF5: Bao cao hoat dong dau tu thang 04/2026
source.source_key: vn_hsx_listed_company_news
metadata.fetch_mode: live

story_key: breaking-2026-05-11-2460981
headline: FUCTVGF4: Bao cao hoat dong dau tu thang 04/2026
source.source_key: vn_hsx_listed_company_news
metadata.fetch_mode: live
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
1. Repeat HNX manual staging live poll smoke in another observation window.
2. Repeat HSX manual staging live poll smoke in another observation window.
3. Continue APAC official-source scanning within official exchange/OAM surfaces.
4. Keep KR deferred until the dedicated KR backend/source authority path exists.
5. Keep JP blocked until issue #339 source authority is resolved.
```
