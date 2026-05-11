# GlobalPulse HKEX Staging Workflow Implementation

Date: 2026-05-11 KST

This document records the staging-only workflow wiring for the inactive HKEX Latest Listed Company Information source candidate.

This implementation adds HKEX only to the existing GitHub Actions staging smoke workflow. It does not set the source active, does not enable production scheduled polling, does not change the backend public JSON shape, does not add frontend UI, and does not fetch HKEX PDF/HTM/detail document bodies.

## Conclusion

```text
HKEX_CONSERVATIVE_STAGING_WORKFLOW_ADDED
HKEX_SCHEDULED_STAGING_CRON_CONFIGURED
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_REMAINS_MANUAL_STAGING_ONLY
HKEX_PRODUCTION_SCHEDULED_POLLING_NOT_APPROVED
HKEX_ATTACHMENT_BODY_FETCH_STILL_DISABLED
NO_CNTW_PRODUCTION_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Workflow Change

Workflow:

```text
.github/workflows/globalpulse-live-staging-poll.yml
```

Added scheduled staging cron:

```text
22 */2 * * 1-5
```

Resolution:

```text
event: schedule
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
EDITION: breaking
BACKEND_URL: https://globalpulse-backend-staging.fly.dev
```

This uses the existing single-source smoke path:

```text
GET /api/health
POST /api/admin/sources/hkex_latest_listed_company_information/poll?use_live_fetch=true&edition=breaking
GET /api/feed/digest/latest?edition=breaking
digest.metadata.fallback_to_fixture=false
artifact upload for health/poll/digest JSON
```

## Design Basis

Design record:

```text
globalpulse_hkex_staging_cadence_design.md
```

Evidence records:

```text
globalpulse_hkex_manual_staging_smoke_results.md
globalpulse_hkex_second_manual_observation_results.md
globalpulse_hkex_public_pages_browser_smoke_results.md
```

The selected cadence is intentionally conservative and staging-only:

```text
every 2 hours
weekdays only
single-source mode
not paired with EU or Denmark canary minute
not a completeness claim for all HKEX announcements
```

## Required First Scheduled Run Evidence

After this workflow lands on the default branch, the first automated scheduled HKEX run must be recorded separately.

Expected first-run markers:

```text
workflow: GlobalPulse live staging poll
event: schedule
schedule: 22 */2 * * 1-5
source: hkex_latest_listed_company_information
run_mode: single_source
poll status: 2xx
fetch.mode: live
fetch.status_code: 200
records_seen <= 25
records_inserted <= records_seen
digest status: 2xx
digest.metadata.fallback_to_fixture: false
source remains active=false
```

## Guardrails

```text
Do not set source active=true in this PR.
Do not add HKEX to production scheduled polling.
Do not claim complete HKEX coverage from latest-five JSON alone.
Do not fetch HKEX PDF, HTM, detail, or attachment bodies.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Next Gate

```text
Record HKEX first scheduled staging run
```
