# GlobalPulse Public Web Smoke Daily Schedule Follow-up Pending

Date: 2026-05-12 KST

This document records a follow-up observation that the `GlobalPulse public web smoke` daily schedule still has not produced an observed `event=schedule` run in the inspected Actions result set.

This is documentation-only. It does not change workflows, frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_FOLLOWUP_PENDING_RECORDED
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_STATE_ACTIVE_PREVIOUSLY_VERIFIED
GLOBALPULSE_PUBLIC_WEB_SMOKE_MAIN_FILE_PRESENT_PREVIOUSLY_VERIFIED
NO_PUBLIC_WEB_SMOKE_EVENT_SCHEDULE_RUN_OBSERVED_YET
NO_PUBLIC_WEB_OUTAGE_CLAIMED
FLY_STAGING_DIGEST_RECHECK_200_FALLBACK_FALSE
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Schedule Context

The daily schedule is:

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
cron: 17 0 * * *
default pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
default backend_url: https://globalpulse-backend-staging.fly.dev
default edition: breaking
```

The liveness state review previously confirmed:

```text
workflow id: 274668919
workflow state: active
main workflow file fetch: 200
schedule marker present: true
```

## Follow-up Run-list Evidence

Recent `GlobalPulse public web smoke` workflow runs inspected through the GitHub Actions API still showed only manual dispatch runs:

```text
run id: 25677329262
event: workflow_dispatch
status: completed
conclusion: success
created_at: 2026-05-11T14:45:32Z
head_branch: main

run id: 25676030410
event: workflow_dispatch
status: completed
conclusion: success
created_at: 2026-05-11T14:22:12Z
head_branch: main
```

No `event=schedule` run for this workflow was present in the inspected result set.

## Public Backend Context

Fly staging digest recheck during this follow-up remained healthy:

```text
endpoint: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-12
generated_at: 2026-05-12T04:05:01Z
item_count: 10
metadata.fallback_to_fixture: false
first observed source: india_nse_announcements
```

Production approval trackers remained unchanged:

```text
issue #561: open, comments=0
issue #565: open, comments=0
```

## Interpretation

This remains a scheduled-run observation gap, not a public website outage:

```text
manual public web smoke dispatch evidence remains pass
workflow state and default-branch file were previously verified
public backend digest recheck returned 200 with fallback=false
first daily schedule event remains pending
```

Do not claim `GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_PASS` until a real Actions run with:

```text
event: schedule
workflow: GlobalPulse public web smoke
conclusion: success
```

is observed.

## Follow-up

Next safe actions:

```text
continue checking the GlobalPulse public web smoke workflow run list
record the first daily scheduled public web smoke run when event=schedule appears
if an event=schedule run appears and fails, inspect job logs before changing workflow code
keep manual public smoke and scheduled public smoke evidence separate
keep production config promotion blocked until production approval values exist
```

## Later Update

A later readonly review confirmed the repository default branch is `main` and that the public web smoke workflow file with the daily cron marker is present on `main`. That review is recorded in:

```text
globalpulse_public_web_smoke_default_branch_schedule_review_20260512.md
```

A later scheduled run was observed and passed:

```text
workflow: GlobalPulse public web smoke
run id: 25712711038
event: schedule
conclusion: success
created_at: 2026-05-12T04:07:00Z
artifact: globalpulse-public-web-smoke-25712711038
```

That successful first daily scheduled run is recorded in:

```text
globalpulse_public_web_smoke_first_daily_schedule_run_results_20260512.md
```

## Guardrails

```text
Do not treat this pending scheduled run as a public website outage.
Do not promote frontend config to production from this observation.
Do not enable production scheduled polling.
Do not change backend digest JSON response shape.
Do not change workflow schedules in this observation PR.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not set candidate sources active=true.
```
