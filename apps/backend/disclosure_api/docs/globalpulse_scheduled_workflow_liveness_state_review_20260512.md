# GlobalPulse Scheduled Workflow Liveness State Review

Date: 2026-05-12 KST

This document records a readonly liveness-state review for the GlobalPulse scheduled workflows after the scheduled staging poll no-new-run gap observation.

This is documentation-only. It does not change workflow schedules, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
GLOBALPULSE_SCHEDULED_WORKFLOW_LIVENESS_STATE_REVIEW_RECORDED
GLOBALPULSE_LIVE_STAGING_POLL_WORKFLOW_STATE_ACTIVE
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_STATE_ACTIVE
MAIN_WORKFLOW_FILES_PRESENT
SCHEDULE_MARKERS_PRESENT
NO_DISABLED_WORKFLOW_BLOCKER_OBSERVED
NO_NEW_RUN_GAP_REMAINS_WAIT_STATE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Workflow State Evidence

Readonly GitHub Actions workflow metadata checks returned:

```text
workflow: GlobalPulse live staging poll
workflow id: 272984043
path: .github/workflows/globalpulse-live-staging-poll.yml
state: active
created_at: 2026-05-08T01:12:51.000Z
updated_at: 2026-05-08T01:12:51.000Z

workflow: GlobalPulse public web smoke
workflow id: 274668919
path: .github/workflows/globalpulse-public-web-smoke.yml
state: active
created_at: 2026-05-11T13:08:11.000Z
updated_at: 2026-05-11T13:08:11.000Z
```

This check did not observe a disabled workflow-state blocker.

## Default Branch File Evidence

Raw workflow fetches from `main` returned:

```text
GET main/.github/workflows/globalpulse-live-staging-poll.yml: 200
GET main/.github/workflows/globalpulse-public-web-smoke.yml: 200
live staging poll schedule marker present: true
public web smoke cron marker present: true
public web smoke cron: 17 0 * * *
```

This confirms the scheduled workflow files are present on the default branch and still contain schedule markers.

## Current Run-list Context

The no-new-run wait state remains:

```text
latest observed GlobalPulse live staging poll scheduled run: 25704707578
event: schedule
conclusion: success
created_at: 2026-05-12T00:03:29Z
head_sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
interpreted source key: sec_press_releases
```

The `GlobalPulse public web smoke` workflow still has no observed `event=schedule` run in the inspected result set. The observed public web smoke runs remained `workflow_dispatch` runs.

## Interpretation

This observation narrows the no-new-run gap:

```text
workflow disabled state was not observed
default-branch workflow-file absence was not observed
schedule markers are still present
no source failure is claimed without a matching failed scheduled run
public web daily smoke pass is still pending until an event=schedule run appears
```

The next source-specific observation should still wait for a matching scheduled run and log evidence. Do not infer HKEX, EU, Denmark, or India source failure from the absence of a newer matching run.

## Follow-up

Next safe actions:

```text
continue checking recent GlobalPulse live staging poll runs
inspect logs when a new matching scheduled run appears
record source-specific observation only after SOURCE_KEY and SCHEDULE_EXPR are verified
record public web daily scheduled smoke only after event=schedule appears
keep digest diversity observations separate from poll success
keep production approval blockers open until operator values are provided
```

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
Do not count workflow_dispatch as a scheduled pass.
JP live polling remains blocked by issue #339.
KR remains deferred until the dedicated backend/source path exists.
```
