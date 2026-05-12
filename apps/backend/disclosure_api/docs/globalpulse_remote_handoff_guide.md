# GlobalPulse Remote Handoff Guide

Last updated: 2026-05-12 KST

This guide is the remote source of truth for continuing GlobalPulse work across multiple local machines.

If a local environment changes, start here before writing code.

Repo-root quick entrypoint:

```text
GLOBALPULSE_HANDOFF.md
```

Public website deployment roadmap:

```text
globalpulse_web_deployment_workflow_roadmap.md
```

Current website implementation checkpoint:

```text
globalpulse_web_implementation_current_checkpoint.md
```

Frontend runtime config promotion design:

```text
globalpulse_frontend_runtime_config_promotion_design.md
```

Frontend staging config marker:

```text
globalpulse_frontend_config_version_marker.md
```

Frontend staging config marker public smoke:

```text
globalpulse_frontend_config_marker_public_smoke_results.md
```

HKEX scheduled staging pending status:

```text
globalpulse_hkex_scheduled_staging_pending_status.md
```

HKEX first automated scheduled staging run:

```text
globalpulse_hkex_first_automated_scheduled_run_results.md
```

HKEX scheduled staging follow-up observation:

```text
globalpulse_hkex_scheduled_staging_followup_observation_20260512.md
```

EU scheduled staging canary second follow-up observation:

```text
globalpulse_eu_scheduled_staging_canary_second_followup_observation_20260512.md
```

Denmark DFSA OAM second scheduled follow-up observation:

```text
globalpulse_denmark_dfsa_oam_second_followup_scheduled_observation_20260512.md
```

India NSE interim scheduled observation:

```text
globalpulse_india_nse_interim_scheduled_observation_20260512.md
```

Post-expansion next-step plan:

```text
globalpulse_post_expansion_next_step_plan.md
```

Remaining website implementation workflow:

```text
globalpulse_web_remaining_implementation_workflow.md
```

Latest public web digest diversity observation:

```text
globalpulse_public_web_digest_diversity_observation_20260512.md
```

Latest source-health drift observation:

```text
globalpulse_source_health_drift_observation_20260512.md
```

Latest production approval blocker status:

```text
globalpulse_production_approval_blocker_status_20260512.md
```

Operator approval intake packet:

```text
globalpulse_operator_approval_intake_packet.md
```

Production CORS smoke contract template:

```text
globalpulse_production_cors_smoke_contract_template.md
```

Production bounded empty digest policy:

```text
globalpulse_production_bounded_empty_digest_policy.md
```

Production frontend empty-state smoke checklist:

```text
globalpulse_production_frontend_empty_state_smoke_checklist.md
```

Production rollback stop checklist:

```text
globalpulse_production_rollback_stop_checklist.md
```

Production deployment smoke record template:

```text
globalpulse_production_deployment_smoke_record_template.md
```

Source production promotion decision template:

```text
globalpulse_source_production_promotion_decision_template.md
```

Public web smoke daily schedule:

```text
globalpulse_public_web_smoke_daily_schedule.md
```

First daily scheduled public web smoke pending observation:

```text
globalpulse_public_web_smoke_first_daily_schedule_pending_20260512.md
```

Public web smoke daily schedule follow-up pending observation:

```text
globalpulse_public_web_smoke_daily_schedule_followup_pending_20260512.md
```

Public web smoke default-branch schedule review:

```text
globalpulse_public_web_smoke_default_branch_schedule_review_20260512.md
```

First successful daily scheduled public web smoke run:

```text
globalpulse_public_web_smoke_first_daily_schedule_run_results_20260512.md
```

Latest scheduled staging poll no-new-run gap observation:

```text
globalpulse_scheduled_staging_poll_no_new_run_gap_observation_20260512.md
```

Scheduled workflow liveness review checklist:

```text
globalpulse_scheduled_workflow_liveness_review_checklist.md
```

Latest scheduled workflow liveness state review:

```text
globalpulse_scheduled_workflow_liveness_state_review_20260512.md
```

Latest staging digest transient retry observation:

```text
globalpulse_staging_digest_transient_500_retry_observation_20260512.md
```

Latest SEC hourly scheduled run after liveness gap:

```text
globalpulse_sec_hourly_scheduled_run_after_liveness_gap_20260512.md
```

Production backend deployment design:

```text
globalpulse_production_backend_deployment_design.md
```

Production deployment runbook:

```text
globalpulse_production_deployment_runbook.md
```

## Current Repository Anchor

```text
repo: suam4597-ship-it/disclosure-automation
primary working branch: phase0-foundation
current anchor commit: 974847921b1680e86438e2063c03a907f35470b6
latest phase0 anchor PR: #606 Add GlobalPulse source promotion decision template
default-branch schedule activation PR: #541 Activate HKEX staging schedule on main
main schedule activation commit: 423ca7fa710b04de56a74b0a1ee092b43597b8a1
default-branch public web smoke activation PR: #545 Activate public web smoke workflow on main
main public web smoke activation commit: 8a2a4b5279f578c1ab62622768acf6d0adbbb2ab
backend staging: https://globalpulse-backend-staging.fly.dev
public Pages UI: https://suam4597-ship-it.github.io/disclosure-automation/
```

The anchor commit is a checkpoint, not a permanent pin. If `origin/phase0-foundation` is newer, use the newer remote head after reviewing the latest commits.

## Local Bootstrap

```powershell
git clone https://github.com/suam4597-ship-it/disclosure-automation.git
cd disclosure-automation
git checkout phase0-foundation
git fetch origin --prune
git pull --ff-only origin phase0-foundation
git rev-parse HEAD
git status --short
```

Expected:

```text
git status --short: empty
HEAD: 974847921b1680e86438e2063c03a907f35470b6 or a newer origin/phase0-foundation commit
```

If the local checkout has unrelated uncommitted work, do not overwrite it. Either use a fresh clone or create a new branch and inspect the diff first.

## Standard Verification Commands

From `apps/backend/disclosure_api`:

```powershell
mix.bat deps.get
mix.bat format --check-formatted
$env:MIX_ENV='test'; mix.bat compile --warnings-as-errors
```

Focused tests depend on the PR scope. Avoid running the full suite blindly if the goal is a docs-only handoff or endpoint scan.

After validation, remove local dependency/build artifacts unless intentionally changed:

```powershell
$root = Resolve-Path "."
$targets = @("_build", "deps", "mix.lock") | ForEach-Object { Join-Path $root $_ }
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    $resolved = Resolve-Path -LiteralPath $target
    if ($resolved.Path.StartsWith($root.Path)) {
      Remove-Item -LiteralPath $resolved.Path -Recurse -Force
    } else {
      throw "Refusing to remove outside app root: $($resolved.Path)"
    }
  }
}
git status --short
```

Do not commit `_build`, `deps`, or generated `mix.lock` unless a separate dependency-change task explicitly requires it.

## Current Product Phase

GlobalPulse is in this phase:

```text
public Pages UI connected to Fly staging backend
Europe broad listed-company disclosure expansion checkpoint reached
Europe scheduled staging observation in progress
APAC/CN-TW official listed-company disclosure source verification in progress
production scheduled polling not approved
current public Pages smoke: 200
current Fly staging health: 200 ok
current Fly staging digest: 200, item_count=12, fallback=false
latest digest diversity observation: public scheduled smoke top-N includes HKEX, EU Euronext, and India
first daily scheduled public web smoke run: pass, run 25712711038, event=schedule
source-health drift observation: real source keys reachable; workflow canary aliases are not registered source-health keys
production approval blocker status: #561 open comments=1 approval request posted, #565 open comments=1 approval request posted
scheduled staging poll no-new-run gap: superseded by later SEC/EU/HKEX scheduled success runs
scheduled workflow liveness review checklist: use before changing schedules after a no-new-run gap
scheduled workflow liveness state review: live staging poll and public web smoke workflows active on main
staging digest transient 500 retry observation: one digest 500 recovered to 200, health remained 200 ok
SEC hourly scheduled run after gap: pass, run 25712461043, source sec_press_releases, poll 202, live/200, records_seen=25, records_inserted=25, digest fallback=false
public web smoke daily schedule follow-up: resolved by first scheduled pass run 25712711038
public web smoke default-branch schedule review: default_branch=main, workflow file present on main, daily cron marker present
public web smoke first daily scheduled run: pass, run 25712711038, digest item_count=12, fallback=false, HKEX/EU/India rows observed
```

The project is no longer in the "can we find sources?" phase for Europe. Europe now needs observation, promotion gates, digest diversity checks, and rollback evidence.

APAC/CN-TW is still in selective source-verification mode.

## Current Status By Track

### Europe

```text
Europe broad expansion: checkpoint reached
EU first scheduled staging canary: automated cron success recorded
EU canary payload review: recorded
EU canary second follow-up scheduled run: pass, run 25698983703
EU canary latest scheduled run: pass, run 25712655792
Denmark DFSA OAM:
  manual source: registered inactive
  repeated page-1 smoke: pass
  manual canary dispatch: pass
  scheduled staging canary configured on main
  first automated scheduled run: pass
  follow-up scheduled runs: pass, runs 25680895829, 25699532618, and 25713328609
  latest inspected top-N digest visibility: not present in the 2026-05-12 public web digest diversity observation
production EU scheduled polling: not enabled
```

Allowed Europe work:

```text
scheduled observation summaries
source-health drift checks
digest diversity and public Pages visibility checks
rollback/promotion readiness gates
Ireland Dublin-only positive machine filter if proven
bug fixes for already registered sources
```

Pause broad Europe source discovery unless a high-confidence official endpoint or blocker follow-up is already in scope. The default next phase is production-readiness decision work plus scheduled observation, not more broad source expansion.

### India

```text
India NSE official RSS: inactive/manual staging source
staging schedule: configured
first automated scheduled staging run: pass
interim scheduled observation: pass, recent runs 25694981715, 25699447717, 25703573653, and 25713273293
next gate: 7-day observation window and final scheduled run summary
production scheduled polling: not enabled
```

### ASEAN / APAC

```text
SET Thailand: inactive source candidate added; manual and repeated staging smoke pass
Vietnam HNX: inactive RSS source added; manual and repeated staging smoke pass
Vietnam HSX: inactive RSS source added; manual and repeated staging smoke pass
IDX Indonesia: official path reviewed; source registration blocked by Cloudflare/challenge-cookie dependency
SGX: official path reviewed; source registration blocked pending policy/runtime decision
Bursa: official path reviewed; source registration blocked by runtime/access constraints
ASX: technical JSON path strong, but source registration blocked pending written authority or approved information-service path
PSE EDGE: official path reviewed; source registration blocked pending approved data access path
```

### Greater China

```text
Taiwan MOPS: inactive source candidate added; manual and repeated staging smoke pass
HKEX:
  listed-company endpoint scan: recorded
  local Elixir runtime probe: pass
  latest listed-company JSON asset scan: recorded
  bounded parser/source contract: recorded
  Fly/application-runtime homecat0_e.json probe: pass
  source registration: inactive/manual staging-only candidate added
  source status: active=false
  Fly staging deploy: pass
  manual live poll: pass
  second manual observation: pass
  latest digest visibility: pass
  public Pages browser visibility: pass
  source health after poll: healthy
  staging cadence design: recorded
  conservative staging workflow: configured
  default-branch schedule activation: merged to main
  first automated scheduled staging run: pass, run 25684138207
  follow-up scheduled staging observation: 5 successful runs recorded, latest run 25712752961
  next gate: continue scheduled staging observation toward 7-day / 10 successful run gate
```

### Korea / Japan

```text
KR live source track: deferred until dedicated backend/source path exists
JP live polling: blocked by issue #339 until source authority decision
```

## Recommended Next Work Queue

1. Use globalpulse_web_remaining_implementation_workflow.md as the website workflow queue.
2. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
3. Continue EU scheduled staging canary observation summaries and digest-diversity checks as runs accumulate.
4. Continue Denmark DFSA OAM scheduled observation summaries and digest-diversity checks as runs accumulate.
5. Continue India NSE 7-day staging observation.
6. Keep public Pages + Fly staging web smoke workflow healthy after first scheduled pass run 25712711038.
7. Record future digest diversity regressions or recoveries as scheduled observations accumulate.
8. Revisit Taiwan/SET/Vietnam cadence only through staging-only design PRs.
9. Use production deployment templates only after production backend app/database/CORS choices are approved.
10. Record production infrastructure decision values only after operator approval in issue #561.

## HKEX Next-Step Contract

Preferred next HKEX path:

```text
source_key candidate: hkex_latest_listed_company_information
source URL candidate: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
source type: api
region: hk / greater_china
parser target: newsInfo rows
first candidate scope: metadata and announcement links only
attachment/PDF/detail fetch: out of scope
source status: active=false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
runtime GET verification: globalpulse_hkex_fly_runtime_probe_results.md
candidate note: globalpulse_hkex_inactive_source_candidate_notes.md
manual staging smoke: globalpulse_hkex_manual_staging_smoke_results.md
second manual observation: globalpulse_hkex_second_manual_observation_results.md
public Pages browser smoke: globalpulse_hkex_public_pages_browser_smoke_results.md
staging cadence design: globalpulse_hkex_staging_cadence_design.md
staging workflow implementation: globalpulse_hkex_staging_workflow_implementation.md
```

Completed before manual staging verification:

```text
bounded parser contract document: globalpulse_hkex_latest_listed_company_parser_contract.md
fixture with representative homecat0_e.json payload
local parser smoke
application or Fly runtime GET verification: recorded
explicit no-PDF/no-detail-fetch guardrail
backend digest JSON shape unchanged
```

Current HKEX gate:

```text
manual staging live poll: pass
second manual observation: pass
digest visibility: pass
public Pages browser visibility: pass
source health: healthy
source remains active=false
candidate_status remains manual_staging_only
cadence: not approved
staging cadence design: recorded
staging workflow: configured
first scheduled run: pass, run 25684138207
follow-up scheduled observation: 5 successful scheduled runs recorded, latest run 25712752961
next: continue scheduled observation, keep source active=false
```

## GitHub Actions Checks To Review

Useful workflow:

```text
GlobalPulse live staging poll
```

Important runs to know:

```text
EU canary payload review run: 25650523685
EU canary second follow-up run: 25698983703
EU canary latest scheduled run: 25712655792
India NSE first scheduled run: 25650796284
India NSE interim observation recent runs: 25694981715, 25699447717, 25703573653, and 25713273293
Denmark DFSA OAM first automated scheduled run: 25668194957
Denmark DFSA OAM second follow-up run: 25699532618
Denmark DFSA OAM latest scheduled run: 25713328609
HKEX first automated scheduled staging run: 25684138207
HKEX follow-up scheduled staging observation latest run: 25712752961
HKEX scheduled staging cron: 22 */2 * * 1-5
HKEX main activation PR: #541
HKEX main activation commit: 423ca7fa710b04de56a74b0a1ee092b43597b8a1
Public web smoke workflow: globalpulse-public-web-smoke.yml
Public web smoke phase0 PR: #544
Public web smoke main activation PR: #545
Public web smoke workflow id: 274668919
Public web smoke first workflow_dispatch run: 25676030410 pass
Public web smoke first event=schedule run: 25712711038 pass
Latest scheduled staging poll no-new-run gap: superseded by later SEC/EU/HKEX scheduled success runs
Latest SEC hourly scheduled run after gap: 25712461043
```

Useful branch checks:

```text
Phase 0 validate
Phase 0 report
Phase 1 backend verify
Phase 1 runtime smoke
Phase 1 backend report
Phase 1 backend diagnose
Phase 1 backend trace
```

## Guardrails

```text
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not add frontend framework dependencies.
Do not claim fixture fallback as live success.
Do not register global/cross-market feeds as country-specific without a country-only machine filter.
Do not use central-bank, macro, policy, or generic-news feeds for the listed-company disclosure track.
Do not fetch PDFs, attachments, or detail document bodies in first candidates unless a specific parser/design PR authorizes it.
Do not use browser-only success as backend polling readiness.
Do not bypass challenge/captcha/cookie walls without an explicit access-policy decision.
Do not enable JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## How To Leave A Clean Handoff

Before stopping work on any machine, create or update a docs-only handoff PR if the state changed materially.

Minimum handoff content:

```text
branch/head
latest merged PR
worktree status
what changed
what passed
what is pending
exact next command or next PR title
guardrails
```

Then ensure:

```powershell
git status --short
git log --oneline -5
```

If work is unfinished, push the branch and open a draft PR rather than leaving state only on one machine.
