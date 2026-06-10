# GlobalPulse Public Web Smoke Default Branch Schedule Review

Date: 2026-05-12 KST

This document records a readonly default-branch and workflow-file review for the `GlobalPulse public web smoke` daily schedule.

This is documentation-only. It does not change workflows, frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_DEFAULT_BRANCH_SCHEDULE_REVIEW_RECORDED
REPO_DEFAULT_BRANCH_IS_MAIN
PUBLIC_WEB_SMOKE_WORKFLOW_PRESENT_ON_MAIN
PUBLIC_WEB_SMOKE_SCHEDULE_MARKER_PRESENT_ON_MAIN
PUBLIC_WEB_SMOKE_WORKFLOW_PRESENT_ON_PHASE0_FOUNDATION
NO_DEFAULT_BRANCH_MISMATCH_CAUSE_OBSERVED
NO_PUBLIC_WEB_SMOKE_EVENT_SCHEDULE_RUN_OBSERVED_YET
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Repository Metadata

Readonly GitHub repository metadata returned:

```text
repo: suam4597-ship-it/disclosure-automation
default_branch: main
archived: false
disabled: false
pushed_at: 2026-05-12T04:08:36Z
```

## Workflow File Evidence

Readonly raw workflow fetches returned:

```text
branch: main
GET .github/workflows/globalpulse-public-web-smoke.yml: 200
has schedule marker: true
has daily cron marker `cron: "17 0 * * *"`: true

branch: phase0-foundation
GET .github/workflows/globalpulse-public-web-smoke.yml: 200
has schedule marker: true
has daily cron marker `cron: "17 0 * * *"`: true
```

The earlier liveness review also verified:

```text
workflow id: 274668919
workflow state: active
```

## Run-list Context

The inspected `GlobalPulse public web smoke` workflow run list still showed only manual dispatch runs:

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

No `event=schedule` run was observed in the inspected result set.

## Interpretation

This narrows the pending daily schedule observation:

```text
the repo default branch is main
the workflow file is present on main
the daily cron marker is present on main
the workflow was previously verified active
no default-branch mismatch cause was observed
```

This still does not prove a public website failure. The latest manual public smoke evidence remains pass, and Fly staging digest checks continued to return 200 with `metadata.fallback_to_fixture=false`.

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
if no scheduled run appears in the next observation window, inspect GitHub Actions schedule behavior before changing workflow code
keep manual public smoke and scheduled public smoke evidence separate
keep production config promotion blocked until production approval values exist
```

## Later Update

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
