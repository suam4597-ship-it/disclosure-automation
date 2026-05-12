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

Public web smoke daily schedule:

```text
globalpulse_public_web_smoke_daily_schedule.md
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
current anchor commit: 09062dce6ab0e52bf518990281bb477f6907b8cd
latest phase0 anchor PR: #578 Record India NSE interim scheduled observation
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
HEAD: 09062dce6ab0e52bf518990281bb477f6907b8cd or a newer origin/phase0-foundation commit
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
Denmark DFSA OAM:
  manual source: registered inactive
  repeated page-1 smoke: pass
  manual canary dispatch: pass
  scheduled staging canary configured on main
  first automated scheduled run: pass
  follow-up scheduled runs: pass, runs 25680895829 and 25699532618
  latest digest visibility: pass
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
interim scheduled observation: pass, recent runs 25694981715, 25699447717, 25703573653
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
  follow-up scheduled staging observation: 4 successful runs recorded, latest run 25702861937
  next gate: continue scheduled staging observation toward 7-day / 10 successful run gate
```

### Korea / Japan

```text
KR live source track: deferred until dedicated backend/source path exists
JP live polling: blocked by issue #339 until source authority decision
```

## Recommended Next Work Queue

1. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
2. Continue EU scheduled staging canary observation summaries and digest-diversity checks as runs accumulate.
3. Continue Denmark DFSA OAM scheduled observation summaries and digest-diversity checks as runs accumulate.
4. Continue India NSE 7-day staging observation.
5. Record scheduled-canary digest diversity and public Pages visibility smoke.
6. Keep public Pages + Fly staging web smoke workflow healthy.
7. Revisit Taiwan/SET/Vietnam cadence only through staging-only design PRs.
8. Use production deployment templates only after production backend app/database/CORS choices are approved.
9. Record production infrastructure decision values only after operator approval in issue #561.

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
follow-up scheduled observation: 4 successful scheduled runs recorded, latest run 25702861937
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
India NSE first scheduled run: 25650796284
India NSE interim observation recent runs: 25694981715, 25699447717, 25703573653
Denmark DFSA OAM first automated scheduled run: 25668194957
Denmark DFSA OAM second follow-up run: 25699532618
HKEX first automated scheduled staging run: 25684138207
HKEX follow-up scheduled staging observation latest run: 25702861937
HKEX scheduled staging cron: 22 */2 * * 1-5
HKEX main activation PR: #541
HKEX main activation commit: 423ca7fa710b04de56a74b0a1ee092b43597b8a1
Public web smoke workflow: globalpulse-public-web-smoke.yml
Public web smoke phase0 PR: #544
Public web smoke main activation PR: #545
Public web smoke workflow id: 274668919
Public web smoke first workflow_dispatch run: 25676030410 pass
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
