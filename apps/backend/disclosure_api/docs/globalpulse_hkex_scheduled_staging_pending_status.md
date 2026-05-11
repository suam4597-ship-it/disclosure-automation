# GlobalPulse HKEX Scheduled Staging Pending Status

Date: 2026-05-11 KST

This document records the first post-activation check for the HKEX conservative staging schedule.

This is status documentation. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
HKEX_STAGING_WORKFLOW_CONFIGURED
HKEX_MAIN_SCHEDULE_ACTIVATED
FIRST_HKEX_AUTOMATED_SCHEDULED_RUN_NOT_OBSERVED_YET
LATEST_OBSERVED_SCHEDULE_RUN_WAS_INDIA
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
PRODUCTION_HKEX_POLLING_NOT_ENABLED
```

## Expected HKEX Schedule

```text
workflow: GlobalPulse live staging poll
workflow file: .github/workflows/globalpulse-live-staging-poll.yml
cron: 22 */2 * * 1-5
expected source: hkex_latest_listed_company_information
expected run_mode: single_source
backend: https://globalpulse-backend-staging.fly.dev
```

## Check Window

The check waited past the first expected post-activation HKEX window:

```text
expected cron window: 2026-05-11T14:22:00Z
expected cron window KST: 2026-05-11 23:22 KST
waited until approximately: 2026-05-11T14:36Z
result: HKEX scheduled run not found
```

GitHub scheduled workflows can be delayed or skipped. This status is not recorded as source failure because no HKEX workflow run was observed.

## Latest Observed Live Staging Poll Run

Latest schedule run at check time:

```text
run id: 25673025413
event: schedule
created_at: 2026-05-11T13:25:54Z
head sha: 20c2cf42585afb71e55e9954cbc51b8cc8f0b1dc
conclusion: success
resolved schedule: 37 */2 * * 1-5
resolved source: india_nse_announcements
run_mode: single_source
```

That run passed, but it was not the HKEX schedule.

## Next Expected HKEX Window

```text
next expected HKEX cron window: 2026-05-11T16:22:00Z
next expected HKEX cron window KST: 2026-05-12 01:22 KST
```

At or after that window, check:

```powershell
gh run list --repo suam4597-ship-it/disclosure-automation --workflow globalpulse-live-staging-poll.yml --limit 15
```

For any candidate run, verify logs contain:

```text
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
fetch.mode: live
digest.metadata.fallback_to_fixture: false
```

## Guardrails

```text
Do not mark HKEX scheduled staging pass until a real scheduled run is observed.
Do not replace this with a manual workflow_dispatch run.
Do not set HKEX active=true.
Do not enable production HKEX polling.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
```
