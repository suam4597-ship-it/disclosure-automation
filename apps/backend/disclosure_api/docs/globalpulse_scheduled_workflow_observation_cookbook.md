# GlobalPulse Scheduled Workflow Observation Cookbook

Date: 2026-05-12 KST

This document records the repeatable command path for observing GlobalPulse scheduled staging workflows from any local machine.

This is documentation-only. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
SCHEDULED_WORKFLOW_OBSERVATION_COOKBOOK_RECORDED
PHASE0_AND_PHASE1_CI_GREEN_AFTER_PIPELINE_FORMAT_RECOVERY
HKEX_FIRST_AUTOMATED_SCHEDULED_RUN_STILL_PENDING
LATEST_OBSERVED_STAGING_POLL_RUN_WAS_SEC_HOURLY
MANUAL_WORKFLOW_DISPATCH_DOES_NOT_COUNT_AS_SCHEDULED_PASS
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Current Known Status

The latest `phase0-foundation` CI after the pipeline formatting recovery completed successfully:

```text
head: 62922a389913b63aa832799a8cade1bc6270fd00
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

The latest observed `GlobalPulse live staging poll` schedule run during this check was not HKEX:

```text
run id: 25679600068
created_at: 2026-05-11T15:25:27Z
event: schedule
conclusion: success
SCHEDULE_EXPR: 7 * * * *
SOURCE_KEY: sec_press_releases
RUN_MODE: single_source
fetch.mode: live
fetch.status_code: 200
records_seen: 25
records_inserted: 25
digest.metadata.fallback_to_fixture: false
```

This confirms the staging poll workflow is still running, but it is not evidence for HKEX's first automated scheduled run.

## Schedule Map

Use the workflow logs as the authority, not only the run timestamp.

```text
workflow: GlobalPulse live staging poll
workflow file: .github/workflows/globalpulse-live-staging-poll.yml
```

Known schedule routing:

```text
7 * * * *             -> sec_press_releases, single_source
37 */2 * * 1-5        -> india_nse_announcements, single_source
17 */4 * * 1-5        -> eu_scheduled_staging_canary, eu_canary
47 */4 * * 1-5        -> denmark_dfsa_oam_staging_canary, denmark_dfsa_oam_canary
22 */2 * * 1-5        -> hkex_latest_listed_company_information, single_source
```

## Command Path

From repo root:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
git checkout phase0-foundation
git pull --ff-only origin phase0-foundation
git status --short
```

List recent staging poll runs:

```powershell
gh run list --repo suam4597-ship-it/disclosure-automation --workflow globalpulse-live-staging-poll.yml --limit 40 --json databaseId,event,status,conclusion,createdAt,headSha,url,displayTitle |
  ConvertFrom-Json |
  ConvertTo-Json -Depth 8
```

Inspect a candidate run:

```powershell
gh run view <run_id> --repo suam4597-ship-it/disclosure-automation --log
```

For quick triage:

```powershell
gh run view <run_id> --repo suam4597-ship-it/disclosure-automation --log |
  Select-String -Pattern 'SCHEDULE_EXPR|SOURCE_KEY|RUN_MODE|fetch.mode|fallback_to_fixture|records_seen|records_inserted|status_code|poll status|digest contract pass'
```

## HKEX Pass Criteria

Only record `HKEX_FIRST_AUTOMATED_SCHEDULED_STAGING_RUN_PASS` when a real scheduled run satisfies all of the following:

```text
event: schedule
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
poll status: 202
fetch.mode: live
fetch.status_code: 200
records_seen: integer >= 1
records_inserted: integer >= 0 and <= records_seen
digest.metadata.fallback_to_fixture: false
digest contains HKEX latest-listed-company live item or confirms bounded live digest continuity
```

Do not record an HKEX scheduled pass from:

```text
workflow_dispatch
manual Fly curl
manual local curl
public digest visibility from an earlier manual poll
another schedule expression
another source key
fixture fallback
```

## Result PR Template

If the HKEX scheduled run is observed, create a docs-only PR:

```text
title: Record HKEX first automated scheduled staging run
file: apps/backend/disclosure_api/docs/globalpulse_hkex_first_automated_scheduled_staging_run_results.md
```

Required result fields:

```text
run id
run URL
event
created_at
head sha
SCHEDULE_EXPR
SOURCE_KEY
RUN_MODE
backend URL
health result
poll status
fetch.mode
fetch.status_code
records_seen
records_inserted
digest fallback_to_fixture
digest item_count
public UI visibility if checked
warnings
guardrails
```

Required conclusion markers:

```text
HKEX_FIRST_AUTOMATED_SCHEDULED_STAGING_RUN_PASS
HKEX_FETCH_MODE_LIVE
HKEX_DIGEST_FALLBACK_FALSE
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
PRODUCTION_HKEX_POLLING_NOT_ENABLED
```

## If No HKEX Run Exists

If no matching run exists after a check window, keep the status pending and record:

```text
latest observed schedule run id
latest observed schedule expression
latest observed source key
latest observed run mode
next expected HKEX cron window
reason not marked pass: matching scheduled HKEX run not observed
```

Do not treat GitHub schedule delay as an HKEX source failure unless a matching HKEX run actually executes and fails.

## Guardrails

```text
Do not set HKEX active=true.
Do not enable production HKEX polling.
Do not enable broad production scheduled polling.
Do not change workflow schedules while recording observation results.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of observation.
Do not claim fixture fallback as live success.
JP live polling remains blocked by issue #339.
```

