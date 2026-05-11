# GlobalPulse HKEX Manual Staging Smoke Results

Date: 2026-05-11 KST

This document records the first manual Fly staging live-poll smoke for the inactive/manual staging-only HKEX Latest Listed Company Information source candidate.

This is a staging validation record. It does not activate the HKEX source, enable production scheduled polling, add public poll UI, add audit UI, add public Source Health UI, change the public digest JSON response shape, add a frontend framework, or fetch HKEX PDF/HTM/detail document bodies.

## Conclusion

```text
HKEX_MANUAL_STAGING_LIVE_POLL_PASS
HKEX_DIGEST_VISIBLE_LIVE
HKEX_SOURCE_HEALTH_HEALTHY
HKEX_SOURCE_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_MANUAL_STAGING_ONLY
HKEX_LIVE_FIXTURE_FALLBACK_DISABLED
HKEX_ATTACHMENT_BODY_FETCH_DISABLED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
HKEX_CADENCE_NOT_APPROVED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Deployment Context

```text
repo: suam4597-ship-it/disclosure-automation
branch deployed: phase0-foundation
deployed commit: 6473fbc79e668a7c2207effd45aa51d151ba07b2
Fly app: globalpulse-backend-staging
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KRBGBP5A5SNF555GZF4W00AE
backend URL: https://globalpulse-backend-staging.fly.dev
```

The deploy completed with a successful release command and migration step.

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Source Health Before Poll

```text
GET /api/admin/source-health/hkex_latest_listed_company_information
status: 200
source_key: hkex_latest_listed_company_information
parser_key: hkex_latest_listed_company_info_json_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
```

## Manual Live Poll

```text
POST /api/admin/sources/hkex_latest_listed_company_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
fetch.bytes: 1928
records_seen: 5
records_inserted: 5
```

Canonical items inserted:

```text
breaking-2026-05-11-hkex-llci-2026051101351
breaking-2026-05-11-hkex-llci-2026051101348
breaking-2026-05-11-hkex-llci-2026051101346
breaking-2026-05-11-hkex-llci-2026051101344
breaking-2026-05-11-hkex-llci-2026051101342
```

The live poll used the official HKEX `homecat0_e.json` metadata asset. It did not fetch PDF, HTM, announcement detail, or attachment bodies.

## Digest Visibility

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
edition: breaking
digest_date: 2026-05-11
item_count: 12
HKEX source visible: true
```

Observed HKEX digest item:

```text
source_key: hkex_latest_listed_company_information
display_name: HKEX Latest Listed Company Information
story_key: breaking-2026-05-11-hkex-llci-2026051101351
headline: 02579 - CNGR - An announcement has...
canonical_url: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051101351.htm
priority_rank: 1
published_at: 2026-05-11T12:32:00.000000Z
fetch_mode: live
source_type: api
regions: greater_china
coverage_tags: apac, greater_china, hong_kong, hk, disclosure, exchange, listed_companies, issuer_announcement, latest_submissions, markets
```

Bounded summary:

```text
HKEX Latest Listed Company Information | Issuer: 02579 CNGR | Category: Announcements and Notices - [Overseas Regulatory Announcement - Other] | Document: htm | Size: 1KB | Published: 2026-05-11-20:32
```

## Source Health After Poll

```text
GET /api/admin/source-health/hkex_latest_listed_company_information
status: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_seen_published_at: 2026-05-11T12:32:00.000000Z
last_success_at: 2026-05-11T12:34:14.063747Z
```

## Boundary Confirmation

```text
source remains active=false
candidate remains manual_staging_only
fixture fallback remains disabled for live polling
production scheduled polling remains disabled
workflow schedules unchanged
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
HKEX PDF body fetch not added
HKEX HTM/detail body fetch not added
attachment extraction not added
CN/TW scheduled polling remains disabled
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Gate

HKEX is now a live-verified inactive/manual staging-only candidate.

Before considering any cadence:

```text
1. Record at least one additional manual observation window.
2. Confirm digest diversity after HKEX is present with other regional sources.
3. Document rollback behavior if the source is disabled or unavailable.
4. Design a staging-only cadence proposal before any schedule change.
5. Do not enable production scheduled polling without a separate approval gate.
```
