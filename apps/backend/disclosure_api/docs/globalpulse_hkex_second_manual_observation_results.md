# GlobalPulse HKEX Second Manual Observation Results

Date: 2026-05-11 KST

This document records a second manual Fly staging live-poll observation for the inactive/manual staging-only HKEX Latest Listed Company Information source candidate.

This is a staging observation record. It does not activate the HKEX source, enable production scheduled polling, add public poll UI, add audit UI, add public Source Health UI, change the public digest JSON response shape, add a frontend framework, or fetch HKEX PDF/HTM/detail document bodies.

## Conclusion

```text
HKEX_SECOND_MANUAL_OBSERVATION_PASS
HKEX_MANUAL_STAGING_LIVE_POLL_PASS
HKEX_DIGEST_VISIBLE_LIVE
HKEX_SOURCE_HEALTH_HEALTHY
HKEX_SOURCE_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_MANUAL_STAGING_ONLY
HKEX_LIVE_FIXTURE_FALLBACK_DISABLED
HKEX_ATTACHMENT_BODY_FETCH_DISABLED
HKEX_STAGING_CADENCE_DESIGN_RECORDED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Observation Context

```text
backend staging: https://globalpulse-backend-staging.fly.dev
source_key: hkex_latest_listed_company_information
edition: breaking
mode: manual staging live poll
previous smoke record: globalpulse_hkex_manual_staging_smoke_results.md
public browser smoke record: globalpulse_hkex_public_pages_browser_smoke_results.md
```

## Poll Result

```text
POST /api/admin/sources/hkex_latest_listed_company_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
fetch.bytes: 1940
records_seen: 5
records_inserted: 5
```

Canonical items inserted:

```text
breaking-2026-05-11-hkex-llci-2026051101368
breaking-2026-05-11-hkex-llci-2026051101366
breaking-2026-05-11-hkex-llci-2026051101364
breaking-2026-05-11-hkex-llci-2026051101362
breaking-2026-05-11-hkex-llci-2026051101360
```

The second observation again used the official HKEX `homecat0_e.json` metadata asset. It did not fetch PDF, HTM, announcement detail, or attachment bodies.

## Digest Check

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-11
item_count: 12
HKEX item visible: true
observed HKEX headline: 02579 - CNGR - An announcement has...
```

The digest remained bounded and continued to expose HKEX through the existing public digest shape.

## Source Health After Observation

```text
GET /api/admin/source-health/hkex_latest_listed_company_information
status: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_error: null
last_failure_at: null
last_seen_published_at: 2026-05-11T12:42:00.000000Z
last_success_at: 2026-05-11T12:45:53.748632Z
poll_cron: */30 * * * *
```

The `poll_cron` metadata is present in source configuration, but the source remains `active=false`; this observation does not approve or enable scheduled polling.

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

HKEX now has two manual staging live-poll observations plus public Pages browser visibility.

The staging-only cadence design is now recorded in:

```text
globalpulse_hkex_staging_cadence_design.md
```

The next safe step is a separate implementation PR that adds HKEX only to a conservative staging workflow while keeping the source inactive.

Suggested next PR:

```text
Add HKEX conservative staging workflow
```
