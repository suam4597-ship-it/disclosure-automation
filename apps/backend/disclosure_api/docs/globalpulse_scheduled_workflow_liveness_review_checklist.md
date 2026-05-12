# GlobalPulse Scheduled Workflow Liveness Review Checklist

Date: 2026-05-12 KST

This document records a safe checklist for reviewing GlobalPulse scheduled workflow liveness when a scheduled run is not observed in the expected window.

This is documentation-only. It does not change workflow schedules, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
GLOBALPULSE_SCHEDULED_WORKFLOW_LIVENESS_REVIEW_CHECKLIST_RECORDED
NO_NEW_RUN_GAP_TRIAGE_STANDARDIZED
WORKFLOW_STATE_CHECK_BEFORE_SCHEDULE_CHANGE
DEFAULT_BRANCH_FILE_CHECK_BEFORE_SCHEDULE_CHANGE
SOURCE_FAILURE_REQUIRES_MATCHING_FAILED_RUN
PUBLIC_WEB_SMOKE_SCHEDULE_REQUIRES_EVENT_SCHEDULE_RUN
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## When To Use This

Use this checklist when one of these is true:

```text
GlobalPulse live staging poll has no newer scheduled run in the inspected run list
GlobalPulse public web smoke has no event=schedule run yet
a source-specific scheduled observation window is waiting for the next matching run
a run exists but the source key or schedule expression has not been verified from logs
```

Do not use this checklist to justify source activation, production polling, or workflow schedule changes. It is a triage path before changing anything.

## Readonly PowerShell REST Checks

Set a User-Agent once:

```powershell
$headers = @{ 'User-Agent' = 'globalpulse-observation' }
```

Check workflow metadata and enabled state:

```powershell
$live = Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/workflows/globalpulse-live-staging-poll.yml' -TimeoutSec 30
$public = Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/workflows/globalpulse-public-web-smoke.yml' -TimeoutSec 30

$live | Select-Object id,name,path,state,created_at,updated_at | Format-List
$public | Select-Object id,name,path,state,created_at,updated_at | Format-List
```

Confirm the workflow files are present on `main`:

```powershell
$liveFile = Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/suam4597-ship-it/disclosure-automation/main/.github/workflows/globalpulse-live-staging-poll.yml' -TimeoutSec 30
$publicFile = Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/suam4597-ship-it/disclosure-automation/main/.github/workflows/globalpulse-public-web-smoke.yml' -TimeoutSec 30

[pscustomobject]@{
  live_status = $liveFile.StatusCode
  public_status = $publicFile.StatusCode
  live_has_schedule = $liveFile.Content.Contains('schedule:')
  public_has_schedule = $publicFile.Content.Contains('cron: "17 0 * * *"')
} | Format-List
```

List recent staging poll runs:

```powershell
$runs = Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/workflows/globalpulse-live-staging-poll.yml/runs?per_page=30&branch=main' -TimeoutSec 30
$runs.workflow_runs |
  Select-Object id,event,status,conclusion,created_at,head_sha,display_title |
  Format-Table -AutoSize
```

List recent public web smoke runs:

```powershell
$runs = Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/workflows/globalpulse-public-web-smoke.yml/runs?per_page=20' -TimeoutSec 30
$runs.workflow_runs |
  Select-Object id,event,status,conclusion,created_at,head_branch,head_sha |
  Format-Table -AutoSize
```

## Log Inspection Requirement

Run-list metadata is not enough for source-specific pass/fail claims.

For a source-specific scheduled observation, inspect logs and verify:

```text
event: schedule
SCHEDULE_EXPR matches the expected cron
SOURCE_KEY matches the expected source or canary key
RUN_MODE matches the expected mode
poll status is successful or accepted
fetch.mode=live where live evidence is required
fetch.status_code is successful where applicable
records_seen is bounded and parsed
records_inserted is bounded
digest.metadata.fallback_to_fixture=false
```

If `gh` is available:

```powershell
gh run view <run_id> --repo suam4597-ship-it/disclosure-automation --log |
  Select-String -Pattern 'SCHEDULE_EXPR|SOURCE_KEY|RUN_MODE|poll status|fetch.mode|fallback_to_fixture|records_seen|records_inserted|status_code|digest contract pass'
```

If `gh` is unavailable, use the GitHub connector or Actions UI to inspect logs before writing a source-specific observation.

## Interpretation Table

```text
workflow state=active, file present on main, no newer run:
  record as wait-state or GitHub schedule delay; do not claim source failure

workflow state is disabled or file missing on main:
  record workflow liveness blocker; do not edit schedule blindly

new event=schedule run exists but source key is unknown:
  inspect logs before recording source-specific evidence

new event=schedule matching run succeeds:
  record source-specific scheduled observation if enough evidence exists

new event=schedule matching run fails:
  inspect logs, classify source/network/parser/workflow failure, then fix the narrow cause

workflow_dispatch run succeeds:
  useful smoke evidence, but does not count as scheduled pass

public web smoke workflow_dispatch succeeds:
  useful public smoke evidence, but does not count as daily scheduled smoke pass
```

## Current Known Wait-state Baseline

The latest no-new-run gap observation is recorded in:

```text
globalpulse_scheduled_staging_poll_no_new_run_gap_observation_20260512.md
```

The latest liveness-state review is recorded in:

```text
globalpulse_scheduled_workflow_liveness_state_review_20260512.md
```

Baseline from that observation:

```text
latest observed GlobalPulse live staging poll scheduled run: 25704707578
event: schedule
conclusion: success
created_at: 2026-05-12T00:03:29Z
interpreted source key: sec_press_releases
no newer HKEX/EU/Denmark/India matching run observed in the checked list
public web smoke daily event=schedule run still not observed
```

## Guardrails

```text
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not change workflow schedules from this checklist.
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
