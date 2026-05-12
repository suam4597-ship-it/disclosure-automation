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

For the current website implementation checkpoint and cross-local resume path, read:

```text
apps/backend/disclosure_api/docs/globalpulse_web_implementation_current_checkpoint.md
```

For the public Pages + Fly staging smoke workflow contract, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_workflow.md
```

For the first successful public web smoke workflow run, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_workflow_run_results.md
```

For the public web smoke daily schedule, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_daily_schedule.md
```

For the public web smoke daily maintenance verification on `main`, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_daily_maintenance_verification.md
```

For the first daily scheduled public web smoke pending observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_smoke_first_daily_schedule_pending_20260512.md
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

For the first successful HKEX automated scheduled staging run, read:

```text
apps/backend/disclosure_api/docs/globalpulse_hkex_first_automated_scheduled_run_results.md
```

For the HKEX scheduled staging follow-up observation window, read:

```text
apps/backend/disclosure_api/docs/globalpulse_hkex_scheduled_staging_followup_observation_20260512.md
```

For the latest EU scheduled staging canary follow-up observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_eu_scheduled_staging_canary_second_followup_observation_20260512.md
```

For the latest Denmark DFSA OAM scheduled follow-up observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_denmark_dfsa_oam_second_followup_scheduled_observation_20260512.md
```

For the India NSE interim scheduled observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_india_nse_interim_scheduled_observation_20260512.md
```

For the post-expansion next-step plan, read:

```text
apps/backend/disclosure_api/docs/globalpulse_post_expansion_next_step_plan.md
```

For the remaining website implementation workflow, read:

```text
apps/backend/disclosure_api/docs/globalpulse_web_remaining_implementation_workflow.md
```

For the latest public web digest diversity observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_public_web_digest_diversity_observation_20260512.md
```

For the source-observation production readiness matrix, read:

```text
apps/backend/disclosure_api/docs/globalpulse_source_observation_production_readiness_matrix.md
```

For the latest source-health drift observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_source_health_drift_observation_20260512.md
```

For the first monitoring and incident-response plan, read:

```text
apps/backend/disclosure_api/docs/globalpulse_basic_monitoring_incident_plan.md
```

For production backend deployment rules, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_backend_deployment_design.md
```

For the future production deployment operator checklist, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_deployment_runbook.md
```

For the production deployment decision values that still require operator approval, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_deployment_decision_record.md
```

For the latest production approval blocker status, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_approval_blocker_status_20260512.md
```

For future Fly.io production command templates, read:

```text
apps/backend/disclosure_api/docs/globalpulse_production_fly_command_templates.md
```

For future frontend production config promotion templates, read:

```text
apps/backend/disclosure_api/docs/globalpulse_frontend_production_config_templates.md
```

For the latest pipeline formatting CI recovery, read:

```text
apps/backend/disclosure_api/docs/globalpulse_pipeline_format_ci_recovery.md
```

For the scheduled workflow observation command path, read:

```text
apps/backend/disclosure_api/docs/globalpulse_scheduled_workflow_observation_cookbook.md
```

For the latest scheduled staging poll no-new-run gap observation, read:

```text
apps/backend/disclosure_api/docs/globalpulse_scheduled_staging_poll_no_new_run_gap_observation_20260512.md
```

Current remote continuation status:

```text
current phase0 head: 37ae146f2f938572468929cf7f1bf5669cbfe3a4
latest merged PR: #586 Add PowerShell REST observation fallback commands
phase0 public web smoke workflow PR: #544 merged
main public web smoke activation PR: #545 merged
workflow id: 274668919
first workflow_dispatch result: pass, run 25676030410
daily workflow main maintenance verification: pass, run 25677329262
first daily scheduled public web smoke run: pending observation, no event=schedule run observed yet
source-health drift observation: real source keys reachable, workflow canary aliases are not source-health keys
production approval blocker status: #561 open comments=0, #565 open comments=0
HKEX first automated scheduled staging run: pass, run 25684138207
HKEX scheduled staging follow-up observation: 4 successful scheduled runs recorded, latest run 25702861937
next HKEX gate: continue scheduled staging observation toward 7-day / 10 successful run gate
next web deployment gate: decide production backend app/database/frontend URL
post-expansion next gate: production infrastructure decision values, source promotion approvals, and observation-window continuation
web implementation next gate: continue scheduled observations and record digest diversity when non-India rows reappear, then production decision values if approved
production decision record: added, production infra not created
source observation matrix: added, production source promotion not approved
basic monitoring incident plan: added, no alerting runtime enabled
production approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
production Fly command templates: added, commands not executed
frontend production config templates: added, config not promoted
source promotion approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/565
pipeline format CI recovery: pass, merge commit 34c7d06e0503bcf83f64d35a7c4b59b55b64a69e
post-recovery docs CI: pass, head 62922a389913b63aa832799a8cade1bc6270fd00
scheduled workflow observation cookbook: refreshed with PowerShell REST fallback commands
scheduled staging poll no-new-run gap: latest observed scheduled run remains SEC hourly run 25704707578 at 2026-05-12T00:03:29Z
India NSE interim scheduled observation: pass, recent runs 25694981715, 25699447717, 25703573653
EU canary follow-up scheduled observation: pass, runs 25680178601 and 25698983703
Denmark DFSA OAM follow-up scheduled observation: pass, runs 25680895829 and 25699532618
HKEX first automated scheduled staging run: pass, run 25684138207
HKEX scheduled staging follow-up observation: 4/10 successful run gate, latest run 25702861937
public Pages smoke: 200
public config smoke: 200
Fly staging health: 200 ok
Fly staging digest: 200 item_count=10 fallback=false
latest digest diversity observation: India-only top-N, india_nse_announcements=10
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
