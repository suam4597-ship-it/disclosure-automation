# GlobalPulse Handoff

This file is the repo-root pointer for continuing GlobalPulse work across local machines.

For the full current state, next work queue, verification commands, and guardrails, read:

```text
apps/backend/disclosure_api/docs/globalpulse_remote_handoff_guide.md
```

For the public website deployment roadmap, read:

```text
apps/backend/disclosure_api/docs/globalpulse_web_deployment_workflow_roadmap.md
```

For the public Pages + Fly staging smoke workflow contract, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_workflow.md
```

For the first successful public web smoke workflow run, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_workflow_run_results.md
```

For frontend runtime config promotion rules, read:

```text
apps/backend/disclosure_api/docs/globalpulse_frontend_runtime_config_promotion_design.md
```

For the current staging config marker, read:

```text
apps/backend/disclosure_api/docs/globalpulse_frontend_config_version_marker.md
```

For the public smoke result after the staging config marker reached Pages, read:

```text
apps/backend/disclosure_api/docs/globalpulse_frontend_config_marker_public_smoke_results.md
```

For the current HKEX scheduled staging pending status, read:

```text
apps/backend/disclosure_api/docs/globalpulse_hkex_scheduled_staging_pending_status.md
```

For production backend deployment rules, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_backend_deployment_design.md
```

For the future production deployment operator checklist, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_deployment_runbook.md
```

Current remote continuation status:

```text
phase0 public web smoke workflow PR: #544 merged
main public web smoke activation PR: #545 merged
workflow id: 274668919
first workflow_dispatch result: pass, run 25676030410
HKEX first automated scheduled staging run: pending after 2026-05-11T14:22Z window
next HKEX check window: 2026-05-11T16:22Z / 2026-05-12 01:22 KST
next web deployment gate: decide production backend app/database/frontend URL
```

Current public surfaces:

```text
public Pages UI: https://suam4597-ship-it.github.io/disclosure-automation/
Fly staging backend: https://globalpulse-backend-staging.fly.dev
primary working branch: phase0-foundation
```

Recommended local bootstrap:

```powershell
git clone https://github.com/suam4597-ship-it/disclosure-automation.git
cd disclosure-automation
git checkout phase0-foundation
git fetch origin --prune
git pull --ff-only origin phase0-foundation
git rev-parse HEAD
git status --short
```

If `git status --short` is not empty, do not overwrite local work. Use a fresh clone or inspect the diff first.

Keep these guardrails unless a separate PR explicitly changes them:

```text
do not set new sources active=true
do not enable production scheduled polling
do not change backend digest JSON response shape
do not add public poll UI, audit UI, or public Source Health UI
do not fetch PDF/attachment/detail bodies in first source candidates
do not claim fixture fallback as live success
JP live polling remains blocked by issue #339
KR remains deferred until the dedicated backend/source path exists
```
