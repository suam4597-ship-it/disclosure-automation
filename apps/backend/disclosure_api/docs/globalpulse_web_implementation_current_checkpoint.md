# GlobalPulse Web Implementation Current Checkpoint

Date: 2026-05-12 KST

This document records the current website implementation workflow and the exact continuation path for switching between local machines.

This is documentation-only. It does not change frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, secrets, hosting configuration, production infrastructure, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_CONNECTED_TO_FLY_STAGING
PHASE0_AND_PHASE1_CI_GREEN
PUBLIC_PAGES_SMOKE_REACHABLE
FLY_STAGING_HEALTH_PASS
FLY_STAGING_DIGEST_PASS
SOURCE_OBSERVATION_WINDOW_IN_PROGRESS
HKEX_FIRST_AUTOMATED_SCHEDULED_RUN_PASS
HKEX_SCHEDULED_STAGING_FOLLOWUP_OBSERVED
EU_CANARY_SECOND_FOLLOWUP_OBSERVED
DENMARK_DFSA_OAM_SECOND_FOLLOWUP_OBSERVED
INDIA_NSE_INTERIM_SCHEDULED_OBSERVATION_RECORDED
POST_EXPANSION_NEXT_STEP_PLAN_RECORDED
WEB_REMAINING_IMPLEMENTATION_WORKFLOW_RECORDED
CURRENT_PUBLIC_WEB_DIGEST_DIVERSITY_OBSERVATION_RECORDED
SCHEDULED_WORKFLOW_OBSERVATION_COOKBOOK_REFRESHED
FIRST_DAILY_SCHEDULED_PUBLIC_WEB_SMOKE_PENDING_OBSERVATION_RECORDED
SOURCE_HEALTH_DRIFT_OBSERVATION_RECORDED
PRODUCTION_APPROVAL_BLOCKER_STATUS_RECORDED
PRODUCTION_DEPLOYMENT_NOT_APPROVED
REMOTE_HANDOFF_REFRESHED_FOR_MULTI_LOCAL_WORK
```

## Repository Anchor

```text
repo: suam4597-ship-it/disclosure-automation
primary working branch: phase0-foundation
current head: ba8485da6d62598264fb8e980b29c5e3bf2f60cf
latest merged PR: #584 Record GlobalPulse source health drift observation
worktree expectation: clean
```

The head is an anchor for this checkpoint, not a permanent pin. If `origin/phase0-foundation` is newer, use the newer head after reviewing the latest commits and this handoff.

## Website Workflow State

The current website workflow is:

```text
apps/web static GlobalPulse UI
-> GitHub Pages public URL
-> apps/web/config.js runtime API base
-> Fly staging backend
-> /api/health
-> /api/feed/digest/latest?edition=breaking
-> scheduled staging source poll workflows
-> source observation matrix
-> future production approval gates
```

Current public surfaces:

```text
public Pages UI: https://suam4597-ship-it.github.io/disclosure-automation/
public Pages config: https://suam4597-ship-it.github.io/disclosure-automation/config.js
Fly staging backend: https://globalpulse-backend-staging.fly.dev
```

## Current Smoke Snapshot

Checked from a local Windows PowerShell environment:

```text
GET public Pages /: 200
GET public Pages /config.js: 200
GET Fly staging /api/health: 200
health.status: ok
health.service: disclosure_automation
health.phase: phase1
health.repo: up
GET Fly staging /api/feed/digest/latest?edition=breaking: 200
digest.digest_date: 2026-05-12
digest.item_count: 10
digest.metadata.fallback_to_fixture: false
latest observed source distribution: india_nse_announcements=10
latest observed region distribution: india=10
```

This confirms the public website and staging backend are currently connected and live-backed. The latest inspected top-N digest is India-only, so digest diversity remains an observation item. This does not approve production deployment or production scheduled polling.

## Current CI Snapshot

For head `ba8485da6d62598264fb8e980b29c5e3bf2f60cf`, push and pull-request checks completed successfully:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Current Scheduled Observation Snapshot

Recent scheduled staging observations:

```text
India NSE interim scheduled observation runs: 25694981715, 25699447717, 25703573653
India NSE schedule: 37 */2 * * 1-5
India NSE source key: india_nse_announcements
India NSE result: pass, live/200, bounded records, digest fallback=false, India rows visible in inspected top-N digests

EU canary follow-up runs: 25680178601 and 25698983703
EU schedule: 17 */4 * * 1-5
EU source key: eu_scheduled_staging_canary
EU result: pass, all eight canary sources live/200, digest fallback=false; latest inspected digest top-N was India-only, so digest diversity remains under observation

Denmark DFSA OAM follow-up runs: 25680895829 and 25699532618
Denmark schedule: 47 */4 * * 1-5
Denmark source key: denmark_dfsa_oam_staging_canary
Denmark result: pass, live/200, records_seen=25, records_inserted=25, digest fallback=false; latest inspected digest top-N did not include Denmark, so digest diversity remains under observation

HKEX schedule: 22 */2 * * 1-5
HKEX source key: hkex_latest_listed_company_information
HKEX first automated scheduled run: pass, run 25684138207
HKEX result doc: globalpulse_hkex_first_automated_scheduled_run_results.md
HKEX follow-up observation: 4 successful scheduled runs recorded, latest run 25702861937
HKEX follow-up doc: globalpulse_hkex_scheduled_staging_followup_observation_20260512.md
```

HKEX was marked passed only from real `schedule` event artifacts resolving to `source_key=hkex_latest_listed_company_information`. Continue observation before any production schedule decision.

## Resume On Another Local Machine

Start with a fresh or clean checkout:

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
HEAD: ba8485da6d62598264fb8e980b29c5e3bf2f60cf or newer
git status --short: empty
```

Then read these in order:

```text
GLOBALPULSE_HANDOFF.md
apps/backend/disclosure_api/docs/globalpulse_web_implementation_current_checkpoint.md
apps/backend/disclosure_api/docs/globalpulse_remote_handoff_guide.md
apps/backend/disclosure_api/docs/globalpulse_web_deployment_workflow_roadmap.md
apps/backend/disclosure_api/docs/globalpulse_scheduled_workflow_observation_cookbook.md
apps/backend/disclosure_api/docs/globalpulse_source_observation_production_readiness_matrix.md
```

## Fast Health Checks On A New Machine

Check public website and staging backend:

```powershell
(Invoke-WebRequest -UseBasicParsing -Uri 'https://suam4597-ship-it.github.io/disclosure-automation/' -TimeoutSec 20).StatusCode
(Invoke-WebRequest -UseBasicParsing -Uri 'https://suam4597-ship-it.github.io/disclosure-automation/config.js' -TimeoutSec 20).StatusCode
(Invoke-WebRequest -UseBasicParsing -Uri 'https://globalpulse-backend-staging.fly.dev/api/health' -TimeoutSec 20).Content
$digest = Invoke-WebRequest -UseBasicParsing -Uri 'https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking' -TimeoutSec 20
$json = $digest.Content | ConvertFrom-Json
"digest status=$($digest.StatusCode) item_count=$($json.item_count) fallback=$($json.metadata.fallback_to_fixture)"
```

Check latest GitHub Actions status:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
gh run list --repo suam4597-ship-it/disclosure-automation --branch phase0-foundation --limit 16 --json databaseId,workflowName,event,status,conclusion,createdAt,headSha,url |
  ConvertFrom-Json |
  ConvertTo-Json -Depth 8
```

Check scheduled staging poll runs:

```powershell
gh run list --repo suam4597-ship-it/disclosure-automation --workflow globalpulse-live-staging-poll.yml --limit 20 --json databaseId,event,status,conclusion,createdAt,headSha,url,displayTitle |
  ConvertFrom-Json |
  ConvertTo-Json -Depth 8
```

Inspect a candidate scheduled run:

```powershell
gh run view <run_id> --repo suam4597-ship-it/disclosure-automation --log |
  Select-String -Pattern 'SCHEDULE_EXPR|SOURCE_KEY|RUN_MODE|poll status|fetch.mode|fallback_to_fixture|records_seen|records_inserted|status_code|digest contract pass'
```

## Local Backend Verification

If a code change is made under `apps/backend/disclosure_api`, use focused verification first:

```powershell
cd apps/backend/disclosure_api
mix.bat deps.get
mix.bat format --check-formatted
$env:MIX_ENV='test'; mix.bat compile --warnings-as-errors
```

Run focused tests based on the files touched. Avoid full-suite churn for docs-only work.

After local validation, do not commit generated dependency/build artifacts unless a dependency-change task explicitly requires it:

```powershell
git status --short
```

If `_build`, `deps`, `mix.lock`, or crash dumps were generated by local verification and are not intended changes, remove them before committing.

## Recommended Next Work

Current best sequence:

```text
1. Use `globalpulse_web_remaining_implementation_workflow.md` as the website workflow queue.
2. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
3. Continue scheduled observation summaries for EU canary, Denmark DFSA OAM, and India NSE as runs accumulate.
4. Record a new digest diversity observation when non-India rows reappear in the latest top-N digest.
5. Keep daily public web smoke observation healthy.
6. Record the first daily scheduled public web smoke run when an event=schedule run appears.
7. Use source-health drift checks as context when scheduled observation failures appear.
8. Prepare production only after Issue #561 values are approved; latest check has comments=0.
9. Promote sources only after Issue #565 source-by-source approvals are recorded; latest check has comments=0.
```

HKEX pass criteria are recorded in:

```text
apps/backend/disclosure_api/docs/globalpulse_scheduled_workflow_observation_cookbook.md
```

## Production Gates Still Missing

Production is not approved yet because these are still pending:

```text
production backend app/database decision
production DATABASE_URL / SECRET_KEY_BASE / PHX_HOST values
production CORS/origin policy
production frontend API base URL
production frontend hosting/domain decision
source-by-source production promotion approvals
monitoring/alerting owner and thresholds
```

Approval trackers:

```text
production deployment values: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
source promotion approvals: https://github.com/suam4597-ship-it/disclosure-automation/issues/565
JP source authority decision: https://github.com/suam4597-ship-it/disclosure-automation/issues/339
```

## Guardrails

```text
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not repoint public Pages to an unapproved production backend.
Do not reuse staging DB as production by accident.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not add frontend framework dependencies.
Do not claim fixture fallback as live success.
Do not claim latest-window source feeds are complete market coverage.
Do not fetch PDFs, attachments, or detail bodies in first source candidates unless a specific parser/design PR authorizes it.
Do not enable JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Clean Handoff Rule

Before switching machines again:

```powershell
git status --short
git log --oneline -5
```

If the state changed materially, leave a docs-only PR that records:

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

