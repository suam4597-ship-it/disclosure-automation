# GlobalPulse Web Deployment Workflow Roadmap

Date: 2026-05-12 KST

This document records the recommended next workflow for moving GlobalPulse from public staging smoke toward a stable production-grade web deployment.

This is planning-only. It does not change frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, secrets, hosting configuration, or production polling.

## Current State

```text
public UI: GitHub Pages
public URL: https://suam4597-ship-it.github.io/disclosure-automation/
frontend source: apps/web
runtime config: apps/web/config.js
default API base: https://globalpulse-backend-staging.fly.dev
backend hosting: Fly.io staging app
backend app: globalpulse-backend-staging
staging poll workflow: GlobalPulse live staging poll
primary source branch: phase0-foundation
default scheduled workflow branch: main
remote handoff entrypoint: GLOBALPULSE_HANDOFF.md
```

Current validated capabilities:

```text
Pages renders GlobalPulse shell
Pages loads config.js
Pages talks to Fly staging backend
Fly /api/health returns 200
Fly /api/feed/digest/latest?edition=breaking returns bounded JSON
current public Pages smoke: 200
current public config smoke: 200
current Fly staging health smoke: 200 ok
current Fly staging digest smoke: 200 item_count=10 fallback=false
latest digest diversity observation: India-only top-N, india_nse_announcements=10
public browser smoke sees Backend ok and Backend digest live
regional sections render from backend digest data
Source Health operator link is present
HKEX appears in public digest after manual staging poll
source observation production readiness matrix is recorded
basic monitoring and incident-response plan is recorded
```

## Current Gaps

The project is not yet production-deployed in the strict sense because:

```text
frontend points at staging backend by default
there is no separate production Fly backend app recorded
there is no separate production Postgres/database policy recorded
there is no production CORS/origin policy record
there is no stable custom domain decision
there is no production source-promotion approval record
there is no uptime/monitoring/alerting workflow recorded
there is no scheduled production polling approval
```

## Recommended Work Queue

The post-expansion plan is now recorded in:

```text
globalpulse_post_expansion_next_step_plan.md
```

The ordered remaining website implementation workflow is recorded in:

```text
globalpulse_web_remaining_implementation_workflow.md
```

The latest public web digest diversity observation is recorded in:

```text
globalpulse_public_web_digest_diversity_observation_20260512.md
```

Default next posture:

```text
pause broad source expansion by default
continue observation windows
move production infrastructure decisions to the front of the queue
keep production scheduled polling disabled
```

### 1. Record HKEX First Automated Scheduled Staging Run

Blocker:

```text
wait for GitHub Actions schedule 22 */2 * * 1-5 on main
```

Expected run:

```text
workflow: GlobalPulse live staging poll
event: schedule
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
fetch.mode: live
digest.metadata.fallback_to_fixture: false
```

Status:

```text
HKEX first automated scheduled run: pass, run 25684138207
resolved schedule: 22 */2 * * 1-5
resolved source: hkex_latest_listed_company_information
result doc: globalpulse_hkex_first_automated_scheduled_run_results.md
follow-up observation doc: globalpulse_hkex_scheduled_staging_followup_observation_20260512.md
follow-up observation status: 5 successful scheduled runs recorded, latest run 25712752961
historical pending doc: globalpulse_hkex_scheduled_staging_pending_status.md
observation command path: globalpulse_scheduled_workflow_observation_cookbook.md
latest non-HKEX scheduled observations: India runs 25694981715, 25699447717, 25703573653, and 25713273293; EU runs 25680178601, 25698983703, and 25712655792; Denmark runs 25680895829, 25699532618, and 25713328609
```

Output PR:

```text
Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate
```

### 2. Add A Public Web Smoke Workflow

Add a lightweight workflow that runs against the public Pages and Fly staging URLs without changing the product:

```text
GET public Pages URL: 200
HTML contains GlobalPulse shell
GET apps/web/config.js through Pages: 200
GET Fly /api/health: 200
GET Fly /api/feed/digest/latest?edition=breaking: 200
digest item_count > 0
metadata.fallback_to_fixture=false
public response does not expose raw provider/auth/session material
```

Recommended trigger:

```text
workflow_dispatch first
optional schedule later: daily
```

Why this matters:

```text
Phase 0 validates repo artifacts.
Phase 1 validates backend runtime locally.
GlobalPulse live staging poll validates backend/source behavior.
But no single workflow currently validates public Pages + Fly staging as an end-to-end web surface.
```

Status:

```text
workflow added on phase0-foundation: globalpulse-public-web-smoke.yml
default-branch activation: complete via PR #545
default-branch activation commit: 8a2a4b5279f578c1ab62622768acf6d0adbbb2ab
workflow id: 274668919
first workflow_dispatch result: pass, run 25676030410
daily schedule: 17 0 * * *
Node.js action runtime opt-in: FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true
daily main maintenance verification: pass, run 25677329262
Node.js forced-runtime warning: still present, non-blocking
current ad-hoc public Pages/Fly smoke: pass
```

### 3. Split Staging And Production Runtime Configuration

Current `apps/web/config.js` points public Pages to Fly staging by default.

Before production:

```text
decide if GitHub Pages remains staging-only
or add a production config path / branch / domain
or move frontend to a platform with environment-specific config injection
```

Safe next PR:

```text
Design GlobalPulse frontend runtime config promotion
```

Status:

```text
design doc: globalpulse_frontend_runtime_config_promotion_design.md
staging config marker doc: globalpulse_frontend_config_version_marker.md
staging config marker public smoke: globalpulse_frontend_config_marker_public_smoke_results.md
production config template doc: globalpulse_frontend_production_config_templates.md
production backend URL: pending
production config implementation: pending
```

This should decide:

```text
staging API base URL
production API base URL
query-param override policy
CORS allowed origins
cache invalidation/version marker
rollback path
```

### 4. Define Production Backend Target

Staging backend exists:

```text
https://globalpulse-backend-staging.fly.dev
```

Production needs a separate decision:

```text
new Fly app or same app promoted?
new Postgres or shared staging DB?
DATABASE_URL policy
SECRET_KEY_BASE policy
PHX_HOST
CORS origins
backup/retention
deploy rollback
```

Recommended next PR:

```text
Design GlobalPulse production backend deployment
```

Status:

```text
design doc: globalpulse_production_backend_deployment_design.md
decision record: globalpulse_production_deployment_decision_record.md
approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
production Fly app: pending
production database: pending
production secrets: pending
```

Do not create or promote production secrets until this design is reviewed.

### 5. Add Deployment Runbook And Rollback Checklist

The deployment runbook should be one short operational checklist:

```text
deploy backend
run migrations
verify /api/health
verify digest latest
verify public Pages
verify browser rendering
verify CORS
verify source-health guard
record smoke result
rollback backend image if needed
restore previous frontend config if needed
```

Recommended PR:

```text
Add GlobalPulse production deployment runbook
```

Status:

```text
runbook doc: globalpulse_production_deployment_runbook.md
actual production deployment: pending
```

### 6. Promote Sources Only After Observation Windows

Current staging-source tracks should stay separate from production:

```text
SEC: already stable baseline
India NSE: observe 7-day staging window
EU canary: observe scheduled staging canary
Denmark DFSA OAM: observe scheduled staging canary
HKEX: record first scheduled staging run, then observe
Taiwan/SET/Vietnam: cadence only through separate staging designs
JP: blocked by issue #339
KR: deferred
```

Current matrix:

```text
globalpulse_source_observation_production_readiness_matrix.md
```

Production source promotion requires:

```text
run count
failure count
source-health state
digest diversity evidence
public Pages visibility
rollback smoke
explicit source-by-source approval
```

Approval tracker:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/565
```

### 7. Add Basic Monitoring

Before production launch, add a monitoring plan:

```text
Fly health endpoint uptime check
digest freshness check
scheduled poll failure check
Pages availability check
source-health degraded-source review
manual incident checklist
```

Do not add alerting noise until the checks and owners are clear.

Status:

```text
basic monitoring plan: globalpulse_basic_monitoring_incident_plan.md
alerting runtime: not added
production monitoring: not enabled
```

## Preferred Sequence From Here

```text
1. Record HKEX first automated scheduled staging run.
2. Continue public web smoke daily observation.
3. Continue EU, Denmark, and India source observation windows.
4. Keep production backend/frontend decision values in issue #561.
5. Keep source promotion approvals in issue #565.
6. Only then decide production backend + production frontend URL.
```

## What Not To Do Yet

```text
do not repoint public Pages to an unproven production backend
do not reuse staging DB as production by accident
do not enable production scheduled polling
do not set new sources active=true
do not change public digest JSON response shape
do not add public poll UI, audit UI, or public Source Health UI
do not fetch PDF/attachment/detail bodies in first source candidates
do not claim latest-window sources as complete market coverage
do not start JP live polling before issue #339 is resolved
do not start KR live-source implementation before the dedicated backend/source path exists
```
