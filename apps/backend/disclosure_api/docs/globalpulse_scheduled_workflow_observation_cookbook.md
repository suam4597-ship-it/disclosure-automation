# GlobalPulse Scheduled Workflow Observation Cookbook

Date: 2026-05-12 KST

This document records the repeatable command path for observing GlobalPulse scheduled staging workflows from any local machine.

This is documentation-only. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
SCHEDULED_WORKFLOW_OBSERVATION_COOKBOOK_RECORDED
SCHEDULED_WORKFLOW_OBSERVATION_COOKBOOK_REFRESHED
PHASE0_AND_PHASE1_CI_GREEN_AFTER_PUBLIC_DIGEST_OBSERVATION
HKEX_FIRST_AUTOMATED_SCHEDULED_RUN_PASS_RECORDED
HKEX_SCHEDULED_FOLLOWUP_OBSERVATION_RECORDED
LATEST_OBSERVED_STAGING_POLL_RUN_WAS_SEC_HOURLY
MANUAL_WORKFLOW_DISPATCH_DOES_NOT_COUNT_AS_SCHEDULED_PASS
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Current Known Status

The latest `phase0-foundation` CI after the public web digest diversity observation completed successfully:

```text
head: 359ba907962e3dcd55aba2f0013a0c049b9ae15d
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
run id: 25704707578
created_at: 2026-05-12T00:03:29Z
event: schedule
conclusion: success
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

This confirms the staging poll workflow is still running. It is not new evidence for HKEX, EU, Denmark, or India because the resolved source is `sec_press_releases`.

Current observation baselines:

```text
HKEX first automated scheduled run: pass, run 25684138207
HKEX follow-up observation: 4 successful scheduled runs through 25702861937
India NSE interim scheduled observation: recent pass runs 25694981715, 25699447717, 25703573653
EU scheduled staging canary second follow-up: pass, run 25698983703
Denmark DFSA OAM second follow-up: pass, run 25699532618
Latest public web digest diversity observation: pass, 2026-05-12 latest top-N digest India-only
```

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

## HKEX First-run Criteria

The first-run gate has already been recorded in `globalpulse_hkex_first_automated_scheduled_run_results.md`. Keep this criterion here as a historical guardrail for future source schedules.

Only record a first automated scheduled staging run when a real scheduled run satisfies all of the following:

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

Do not record a scheduled pass from:

```text
workflow_dispatch
manual Fly curl
manual local curl
public digest visibility from an earlier manual poll
another schedule expression
another source key
fixture fallback
```

## Follow-up Observation Criteria

For HKEX follow-up observation, continue toward the 7-day / 10 successful run gate. A follow-up observation batch should record:

```text
all matching run ids in the observation window
success count
failure count
latest run id
latest run URL
latest created_at
latest head sha
SCHEDULE_EXPR
SOURCE_KEY
RUN_MODE
latest poll status
latest fetch.mode
latest fetch.status_code
latest records_seen
latest records_inserted
latest digest fallback_to_fixture
whether latest top-N public digest includes HKEX rows
whether source-health is healthy if checked
warning/deprecation notes
guardrails
```

Required conclusion markers for a follow-up batch:

```text
HKEX_SCHEDULED_STAGING_FOLLOWUP_OBSERVED
HKEX_SCHEDULED_STAGING_SUCCESS_COUNT_UPDATED
HKEX_FETCH_MODE_LIVE
HKEX_DIGEST_FALLBACK_FALSE
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
PRODUCTION_HKEX_POLLING_NOT_ENABLED
```

## If No New Matching Run Exists

If no matching source run exists after a check window, do not create a source-specific observation PR just to restate old evidence. During that wait, safe docs-only work includes:

```text
refreshing stale handoff/checkpoint pointers
recording public web smoke/digest diversity if current behavior changed
updating observation cookbooks or decision checklists
checking production approval issues for new operator values
checking source-promotion issue comments for approvals
```

Do not treat GitHub schedule delay as a source failure unless a matching source run actually executes and fails.

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

