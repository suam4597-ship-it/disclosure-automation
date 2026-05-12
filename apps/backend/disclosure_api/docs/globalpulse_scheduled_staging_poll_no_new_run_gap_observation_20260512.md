# GlobalPulse Scheduled Staging Poll No-new-run Gap Observation

Date: 2026-05-12 KST

This document records a wait-state observation for the GlobalPulse scheduled staging poll workflow.

This is documentation-only. It does not change workflow schedules, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
GLOBALPULSE_SCHEDULED_STAGING_POLL_NO_NEW_RUN_GAP_OBSERVED
LATEST_STAGING_POLL_SCHEDULE_RUN_REMAINS_SEC_HOURLY_25704707578
NO_NEW_HKEX_EU_DENMARK_INDIA_MATCHING_RUN_OBSERVED
NO_SOURCE_FAILURE_CLAIMED
PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_STILL_PENDING
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observation

The latest observed `GlobalPulse live staging poll` scheduled run remains:

```text
run id: 25704707578
event: schedule
status: completed
conclusion: success
created_at: 2026-05-12T00:03:29Z
head_sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
interpreted schedule: 7 * * * *
interpreted source key: sec_press_releases
interpreted run mode: single_source
```

During this check, the recent run list did not show a newer scheduled run for the HKEX, EU canary, Denmark DFSA OAM, or India NSE staging schedules.

This is not recorded as a source failure. A source-specific failure can only be claimed after a matching scheduled run executes and fails.

## Public Web Smoke Schedule

The `GlobalPulse public web smoke` workflow still had no observed `event=schedule` run during this check. The observed public web smoke runs remained `workflow_dispatch` runs.

```text
PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_STILL_PENDING
```

## Current Digest Context

The Fly staging digest remained live-backed:

```text
endpoint: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
digest_date: 2026-05-12
edition: breaking
item_count: 10
metadata.fallback_to_fixture: false
source distribution: india_nse_announcements=10
region distribution: india=10
```

This keeps the public website and Fly staging backend in a connected, live-backed state, but the latest top-N digest remains India-only.

## Approval Context

Production approval trackers remained open with no operator decision comments observed:

```text
issue #561: open, comments=0
issue #565: open, comments=0
```

No production infrastructure, production polling, or source promotion decision is implied by this observation.

## Interpretation

This observation should be treated as a scheduling/liveness watch point:

```text
do not mark HKEX failed from the absence of a newer HKEX run
do not mark EU failed from the absence of a newer EU canary run
do not mark Denmark failed from the absence of a newer Denmark run
do not mark India failed from the absence of a newer India run
do not change workflow schedules based only on this single no-new-run gap
```

If the next observation window still shows no new scheduled staging poll runs beyond `25704707578`, inspect workflow enabled state, default-branch schedule health, repository Actions status, and GitHub scheduling delay before changing any workflow behavior.

## Follow-up

Next safe actions:

```text
continue checking the recent GlobalPulse live staging poll run list
inspect logs when a new matching scheduled run appears
record a source-specific observation only from matching run logs
record the first public web smoke daily schedule run when event=schedule appears
continue digest diversity checks
keep production approval blockers open until operator values are provided
```

## Later Update

A later scheduled run showed that `GlobalPulse live staging poll` workflow liveness resumed:

```text
run id: 25712461043
event: schedule
conclusion: success
created_at: 2026-05-12T03:59:01Z
SCHEDULE_EXPR: 7 * * * *
SOURCE_KEY: sec_press_releases
RUN_MODE: single_source
poll status: 202
fetch.mode: live
fetch.status_code: 200
records_seen: 25
records_inserted: 25
digest.metadata.fallback_to_fixture: false
```

That later run is recorded in `globalpulse_sec_hourly_scheduled_run_after_liveness_gap_20260512.md`. It clears the workflow-liveness gap, but it remains SEC evidence rather than HKEX, EU, Denmark, or India evidence.

## Guardrails

```text
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not change workflow schedules in this observation PR.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live success.
Do not infer source failure from a missing scheduled run.
JP live polling remains blocked by issue #339.
KR remains deferred until the dedicated backend/source path exists.
```
