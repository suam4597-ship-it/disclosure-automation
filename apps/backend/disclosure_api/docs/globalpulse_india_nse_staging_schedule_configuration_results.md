# GlobalPulse India NSE Staging Schedule Configuration Results

This document records the configuration result after adding the conservative India NSE staging schedule to the existing GlobalPulse live staging poll workflow.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or production scheduled live polling.

## Conclusion

```text
INDIA_NSE_CONSERVATIVE_STAGING_SCHEDULE_CONFIGURED
INDIA_NSE_DEFAULT_BRANCH_SCHEDULE_ACTIVATED
INDIA_NSE_FIRST_AUTOMATED_SCHEDULED_RUN_PENDING
INDIA_NSE_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SEC_LIVE_STAGING_SCHEDULE_PRESERVED
```

## Baseline

```text
cadence policy PR: #363 Add India NSE scheduled polling cadence policy
workflow PR: #364 Add India NSE staging poll schedule
default branch activation PR: #366 Activate India NSE staging schedule on main
branch: phase0-foundation
merge commit: 5146f3175212bc7cdef140be8f37d8dd2cb51caa
main activation commit: 386562000fc0bc3bebeb3d8bd116c51343d71fbf
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
workflow state: active
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Default Branch Activation

GitHub `schedule` events execute workflow definitions from the repository default branch. The same workflow change was first merged to `phase0-foundation`, but existing scheduled runs still used `main`.

PR #366 applied the workflow-only schedule change to `main` so the NSE cron can be used by GitHub Actions scheduling.

Verified default-branch workflow state:

```text
workflow: GlobalPulse live staging poll
path: .github/workflows/globalpulse-live-staging-poll.yml
state: active
default branch: main
SEC cron present: 7 * * * *
India NSE cron present: 37 */2 * * 1-5
```

## CI Evidence

The #364 merge commit completed successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Workflow Configuration

Existing SEC staging schedule remains:

```text
cron: 7 * * * *
resolved source_key: sec_press_releases
cadence: hourly
```

New India NSE staging schedule:

```text
cron: 37 */2 * * 1-5
resolved source_key: india_nse_announcements
cadence: every 2 hours on weekdays
scope: staging workflow only
```

Manual dispatch behavior remains:

```text
workflow_dispatch source_key input wins when provided
default manual source_key: sec_press_releases
```

## Expected First Scheduled Run

The first automated NSE schedule run is pending the next matching GitHub Actions cron slot.

Expected validation for the first scheduled NSE run:

```text
Health check: success
Poll live source: success
Verify digest: success
poll.fetch.mode: live
poll.fetch.status_code: 200
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
digest.metadata.fallback_to_fixture: false
digest top-12 source/region mix remains bounded
```

## Guardrails Preserved

```text
production scheduled India NSE polling: not enabled
source active flag: false
candidate_status: manual_staging_only
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Next Result To Record

After the first automatic NSE cron completes, record:

```text
workflow run URL
artifact name and id
health.json status
poll.json records_seen and records_inserted
poll.json fetch.mode and fetch.status_code
digest.json item_count and fallback_to_fixture
source and region distribution after scheduled run
```

## Current Conclusion

```text
INDIA_NSE_STAGING_SCHEDULE_CONFIGURATION_READY
INDIA_NSE_DEFAULT_BRANCH_SCHEDULE_READY
NEXT_STEP_RECORD_FIRST_AUTOMATED_NSE_SCHEDULE_RUN
```
