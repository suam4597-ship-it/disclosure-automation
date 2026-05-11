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
HKEX_FIRST_AUTOMATED_SCHEDULED_RUN_PENDING
PRODUCTION_DEPLOYMENT_NOT_APPROVED
REMOTE_HANDOFF_REFRESHED_FOR_MULTI_LOCAL_WORK
```

## Repository Anchor

```text
repo: suam4597-ship-it/disclosure-automation
primary working branch: phase0-foundation
current head: c7331ea7a0ad1020fa6f514980a29e9b2574a9b3
latest merged PR: #571 Record Denmark DFSA OAM follow-up scheduled observation
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
digest.item_count: 12
digest.metadata.fallback_to_fixture: false
```

This confirms the public website and staging backend are currently connected. It does not approve production deployment or production scheduled polling.

## Current CI Snapshot

For head `c7331ea7a0ad1020fa6f514980a29e9b2574a9b3`, push and pull-request checks completed successfully:

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
EU canary follow-up run: 25680178601
EU schedule: 17 */4 * * 1-5
EU source key: eu_scheduled_staging_canary
EU result: pass, all eight canary sources live/200, digest fallback=false

Denmark DFSA OAM follow-up run: 25680895829
Denmark schedule: 47 */4 * * 1-5
Denmark source key: denmark_dfsa_oam_staging_canary
Denmark result: pass, live/200, records_seen=25, records_inserted=25, digest fallback=false

HKEX schedule: 22 */2 * * 1-5
HKEX source key: hkex_latest_listed_company_information
HKEX first automated scheduled run: pending
```

Do not mark HKEX as passed from a manual dispatch, manual Fly curl, public digest visibility, or a different schedule expression.

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
HEAD: c7331ea7a0ad1020fa6f514980a29e9b2574a9b3 or newer
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
1. Keep checking for the HKEX first automated scheduled staging run.
2. If HKEX scheduled run appears, inspect logs and create a docs-only result PR.
3. Continue scheduled observation summaries for EU canary, Denmark DFSA OAM, and India NSE as runs accumulate.
4. Keep daily public web smoke observation healthy.
5. Prepare production only after Issue #561 values are approved.
6. Promote sources only after Issue #565 source-by-source approvals are recorded.
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

