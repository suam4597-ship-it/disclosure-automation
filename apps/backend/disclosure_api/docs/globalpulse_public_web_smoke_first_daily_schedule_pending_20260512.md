# GlobalPulse Public Web Smoke First Daily Schedule Pending

Date: 2026-05-12 KST

This document records the observation that the `GlobalPulse public web smoke` workflow has a daily cron on `main`, but the first `schedule` event run had not appeared yet during this check.

This is documentation-only. It does not change workflows, frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_PRESENT_ON_MAIN
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_DISPATCH_PASS_RECORDED
FIRST_DAILY_SCHEDULED_PUBLIC_WEB_SMOKE_RUN_NOT_OBSERVED_YET
NO_PUBLIC_WEB_SMOKE_FAILURE_OBSERVED
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Evidence

The workflow exists on `main` with the daily cron:

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
cron: 17 0 * * *
default pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
default backend_url: https://globalpulse-backend-staging.fly.dev
default edition: breaking
```

Raw `main` workflow fetch:

```text
GET https://raw.githubusercontent.com/suam4597-ship-it/disclosure-automation/main/.github/workflows/globalpulse-public-web-smoke.yml: 200
schedule marker present: cron: "17 0 * * *"
```

Recent workflow runs inspected through the GitHub Actions API:

```text
workflow: GlobalPulse public web smoke
workflow id: globalpulse-public-web-smoke.yml
run id: 25677329262
event: workflow_dispatch
conclusion: success
created_at: 2026-05-11T14:45:32Z
head_branch: main

run id: 25676030410
event: workflow_dispatch
conclusion: success
created_at: 2026-05-11T14:22:12Z
head_branch: main
```

No `schedule` event run for this workflow was present in the inspected Actions result set.

## Interpretation

The daily public web smoke schedule is present on `main`, but the first scheduled run has not been observed yet. This should remain a pending observation, not a product failure:

```text
manual public web smoke dispatch: pass
latest local public Pages/Fly staging smoke: pass
daily schedule definition: present on main
first daily schedule event: pending observation
```

Do not claim `GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_PASS` until a real Actions run with:

```text
event: schedule
workflow: GlobalPulse public web smoke
conclusion: success
```

is observed.

## Follow-Up

```text
Continue checking the GlobalPulse public web smoke workflow run list.
Record the first daily scheduled public web smoke run when an event=schedule run appears.
If a scheduled run appears and fails, inspect job logs before changing workflow code.
Keep manual public smoke and local public smoke evidence separate from daily scheduled evidence.
```

## Guardrails

```text
Do not treat this pending scheduled run as a public website outage.
Do not promote frontend config to production from this observation.
Do not enable production scheduled polling.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not set candidate sources active=true.
```
