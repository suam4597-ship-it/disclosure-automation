# GlobalPulse Remote Handoff Guide

Last updated: 2026-05-11 KST

This guide is the remote source of truth for continuing GlobalPulse work across multiple local machines.

If a local environment changes, start here before writing code.

## Current Repository Anchor

```text
repo: suam4597-ship-it/disclosure-automation
primary working branch: phase0-foundation
current anchor commit: 6473fbc79e668a7c2207effd45aa51d151ba07b2
latest anchor PR: #535 Add HKEX inactive source candidate
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
HEAD: 6473fbc79e668a7c2207effd45aa51d151ba07b2 or a newer origin/phase0-foundation commit
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
```

The project is no longer in the "can we find sources?" phase for Europe. Europe now needs observation, promotion gates, digest diversity checks, and rollback evidence.

APAC/CN-TW is still in selective source-verification mode.

## Current Status By Track

### Europe

```text
Europe broad expansion: checkpoint reached
EU first scheduled staging canary: automated cron success recorded
EU canary payload review: recorded
Denmark DFSA OAM:
  manual source: registered inactive
  repeated page-1 smoke: pass
  manual canary dispatch: pass
  scheduled staging canary configured on main
  first automated scheduled run: pass
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

Pause broad Europe source discovery unless a high-confidence official endpoint or blocker follow-up is already in scope.

### India

```text
India NSE official RSS: inactive/manual staging source
staging schedule: configured
first automated scheduled staging run: pass
next gate: 7-day observation window and scheduled run summary
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
  latest digest visibility: pass
  source health after poll: healthy
  cadence: not approved
```

### Korea / Japan

```text
KR live source track: deferred until dedicated backend/source path exists
JP live polling: blocked by issue #339 until source authority decision
```

## Recommended Next Work Queue

1. Record Denmark DFSA OAM scheduled observation summary after enough scheduled runs accumulate.
2. Record EU scheduled staging canary observation summary after enough scheduled runs accumulate.
3. Record scheduled-canary digest diversity and public Pages visibility smoke.
4. Continue India NSE 7-day staging observation.
5. Record HKEX manual staging smoke result if not already merged.
6. Run one additional HKEX manual observation window before considering any cadence design.
7. Continue scheduled observation summaries for Europe and India when enough runs accumulate.
8. Revisit Taiwan/SET/Vietnam cadence only through staging-only design PRs.

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
digest visibility: pass
source health: healthy
source remains active=false
candidate_status remains manual_staging_only
cadence: not approved
next: additional manual observation window, then staging-only cadence design if still healthy
```

## GitHub Actions Checks To Review

Useful workflow:

```text
GlobalPulse live staging poll
```

Important runs to know:

```text
EU canary payload review run: 25650523685
India NSE first scheduled run: 25650796284
Denmark DFSA OAM first automated scheduled run: 25668194957
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
