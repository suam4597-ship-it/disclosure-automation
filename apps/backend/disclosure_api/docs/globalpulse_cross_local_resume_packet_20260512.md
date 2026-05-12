# GlobalPulse Cross-Local Resume Packet

Date: 2026-05-12 KST

This document is the shortest handoff path for continuing GlobalPulse work from another local machine.

It is documentation-only. It does not change frontend code, backend code, workflow behavior, routes, public API response shapes, source activation, hosting configuration, production infrastructure, production scheduled polling, public poll UI, audit UI, or public Source Health UI.

## Current State

```text
repo: suam4597-ship-it/disclosure-automation
primary branch: phase0-foundation
latest local handoff head: 68dffc3131cb7fd0109339730ee2c103d5a7e7ba
latest merged PR: #609 Stabilize GlobalPulse public web handoff anchors
previous result PR: #608 Record GlobalPulse public web smoke workflow hardening
workflow hardening PR: #607 Harden GlobalPulse public web smoke workflow
worktree expectation: clean
```

Current product stage:

```text
GlobalPulse public GitHub Pages UI is connected to the Fly staging backend.
Public smoke checks are staging-backed by default.
Source observation and scheduled staging poll evidence are still being accumulated.
Production backend/frontend approval values are not approved yet.
Production scheduled polling is not enabled.
No candidate source has been promoted to production active=true.
```

## Fresh Local Bootstrap

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
HEAD: 68dffc3131cb7fd0109339730ee2c103d5a7e7ba or newer
git status --short: empty
```

If the checkout already has local work, do not overwrite it. Inspect the diff first or use a fresh clone.

## Read Order

Start with these files:

```text
GLOBALPULSE_HANDOFF.md
apps/backend/disclosure_api/docs/globalpulse_remote_handoff_guide.md
apps/backend/disclosure_api/docs/globalpulse_web_implementation_current_checkpoint.md
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_workflow_hardening_results.md
apps/backend/disclosure_api/docs/globalpulse_web_deployment_workflow_roadmap.md
apps/backend/disclosure_api/docs/globalpulse_scheduled_workflow_observation_cookbook.md
apps/backend/disclosure_api/docs/globalpulse_source_observation_production_readiness_matrix.md
```

Use this packet as the quick entrypoint, then use the longer docs above for detail.

## Fast Verification

Public website and staging backend:

```powershell
$pages = Invoke-WebRequest -UseBasicParsing -Uri 'https://suam4597-ship-it.github.io/disclosure-automation/' -TimeoutSec 30
$config = Invoke-WebRequest -UseBasicParsing -Uri 'https://suam4597-ship-it.github.io/disclosure-automation/config.js' -TimeoutSec 30
$health = Invoke-RestMethod -Uri 'https://globalpulse-backend-staging.fly.dev/api/health' -TimeoutSec 30
$digest = Invoke-RestMethod -Uri 'https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking' -TimeoutSec 30

[pscustomobject]@{
  pages_status = $pages.StatusCode
  pages_has_globalpulse = ($pages.Content -like '*GlobalPulse*')
  config_status = $config.StatusCode
  config_has_staging_backend = ($config.Content -like '*globalpulse-backend-staging.fly.dev*')
  health_status = $health.status
  health_service = $health.service
  digest_edition = $digest.edition
  digest_item_count = @($digest.items).Count
  digest_fallback_to_fixture = $digest.metadata.fallback_to_fixture
} | Format-List
```

Expected current shape:

```text
pages_status: 200
pages_has_globalpulse: True
config_status: 200
config_has_staging_backend: True
health_status: ok
health_service: disclosure_automation
digest_edition: breaking
digest_item_count: non-zero in normal staging state
digest_fallback_to_fixture: False
```

Static frontend syntax check:

```powershell
node --check apps/web/config.js
node --check apps/web/script.js

$tmp = Join-Path $env:TEMP 'globalpulse-index-inline-check.js'
$env:GLOBALPULSE_INLINE_TMP = $tmp
@'
import os
import re
from pathlib import Path
html = Path('apps/web/index.html').read_text(encoding='utf-8')
scripts = re.findall(r'<script>(.*?)</script>', html, flags=re.S)
Path(os.environ['GLOBALPULSE_INLINE_TMP']).write_text('\n;\n'.join(scripts), encoding='utf-8')
print(f'extracted inline scripts: {len(scripts)}')
'@ | python -
node --check $tmp
Remove-Item -LiteralPath $tmp -Force
Remove-Item Env:\GLOBALPULSE_INLINE_TMP
```

## GitHub Actions Check

If `gh` is available:

```powershell
gh run list --repo suam4597-ship-it/disclosure-automation --branch phase0-foundation --limit 16 --json databaseId,workflowName,event,status,conclusion,createdAt,headSha,url |
  ConvertFrom-Json |
  ConvertTo-Json -Depth 8
```

If `gh` is unavailable, use REST:

```powershell
$url = 'https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/runs?branch=phase0-foundation&per_page=16'
$runs = Invoke-RestMethod -Headers @{ 'User-Agent' = 'codex' } -Uri $url -TimeoutSec 30
$runs.workflow_runs |
  Select-Object id,name,event,status,conclusion,created_at,head_sha,html_url |
  Format-Table -AutoSize
```

Last known checks for `68dffc3131cb7fd0109339730ee2c103d5a7e7ba`:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## What Was Just Completed

```text
#607 hardened the website deployment/public web smoke workflow.
#608 recorded the #607 result and public surface verification.
#609 stabilized handoff wording so docs-only PRs do not immediately stale the web deployment review anchor.
```

Important #607 behavior:

```text
Pages deploy now checks static JavaScript syntax before artifact upload.
Public web smoke now has production-ready manual inputs.
Scheduled public web smoke remains staging-backed by default.
allow_empty_digest remains false by default.
```

## Next Work Queue

Recommended order:

```text
1. Wait for the next scheduled public web smoke or staging source poll run.
2. Record the run result only if it is a real run with matching workflow/source evidence.
3. Continue scheduled observation windows for HKEX, EU canary, Denmark DFSA OAM, India NSE, and SEC hourly.
4. If #561/#565 receive approved production values, prepare a production config/smoke PR using the existing templates.
5. If no approval values exist, keep working on staging-only observation, docs, and source evidence.
```

Useful result docs/templates:

```text
apps/backend/disclosure_api/docs/globalpulse_production_deployment_runbook.md
apps/backend/disclosure_api/docs/globalpulse_production_deployment_smoke_record_template.md
apps/backend/disclosure_api/docs/globalpulse_production_frontend_empty_state_smoke_checklist.md
apps/backend/disclosure_api/docs/globalpulse_source_production_promotion_decision_template.md
apps/backend/disclosure_api/docs/globalpulse_source_observation_production_readiness_matrix.md
```

## Guardrails

```text
Do not enable production scheduled polling.
Do not create production infrastructure without approved values.
Do not repoint public Pages to an unapproved production backend.
Do not set candidate sources active=true.
Do not treat fixture fallback as production data evidence.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not add a frontend framework.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
Do not commit deps, _build, temporary artifacts, or local test files.
```

## PR Hygiene

For continuation PRs:

```text
base branch: phase0-foundation
prefer small docs-only or test-only PRs while waiting for scheduled runs
record exact run IDs, event type, head SHA, source_key, poll status, digest status, and fallback_to_fixture
use squash merge after mergeable=true
pull phase0-foundation after merge
verify git status --short is empty
```

For source/run evidence, avoid vague claims. Record exact artifacts or response fields instead.
