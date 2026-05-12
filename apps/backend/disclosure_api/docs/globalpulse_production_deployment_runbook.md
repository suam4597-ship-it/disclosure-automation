# GlobalPulse Production Deployment Runbook

Date: 2026-05-11 KST

This runbook is the operator checklist for a future GlobalPulse production backend and frontend promotion.

This is docs-only. It does not deploy production, create secrets, provision databases, change frontend config, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, or promote source candidates.

## Status

```text
RUNBOOK_ADDED
PRODUCTION_BACKEND_NOT_CREATED
PRODUCTION_FRONTEND_CONFIG_NOT_PROMOTED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SOURCE_CANDIDATES_NOT_PROMOTED
```

## Required Inputs

Do not start a production deployment until these are known:

```text
production backend app name
production backend URL
production database attachment
production PHX_HOST
production frontend URL
allowed CORS origins
rollback backend image/release
rollback frontend config commit
operator recording the deployment
```

The decision-record companion document tracks the open approvals:

```text
globalpulse_production_deployment_decision_record.md
```

Fly.io command templates for after approval are recorded in:

```text
globalpulse_production_fly_command_templates.md
```

Frontend production config templates are recorded in:

```text
globalpulse_frontend_production_config_templates.md
```

Secret values must not be pasted into this document, PR descriptions, issue comments, terminal logs, or screenshots.

## Preflight Checklist

Confirm:

```text
phase0-foundation is up to date
GlobalPulse public web smoke workflow exists on main
frontend runtime config promotion design is reviewed
production backend deployment design is reviewed
production backend app/database/secrets are intentionally production-scoped
staging DATABASE_URL is not used for production
production scheduled polling remains disabled
candidate sources remain active=false unless separately approved
```

Suggested local read-only checks:

```powershell
git fetch origin --prune
git checkout phase0-foundation
git pull --ff-only origin phase0-foundation
git status --short
```

Expected:

```text
git status --short is empty
```

## Backend Deployment Checklist

Use the production app name only after it is explicitly approved.

Template:

```powershell
cd apps/backend/disclosure_api
fly deploy --remote-only --app <production-backend-app>
```

Release migration must pass. If release migration fails, stop and use the rollback/fix-forward decision path before touching frontend config.

Record:

```text
deployment command
deployment app
deployment URL
deployment commit SHA
deployment image/release id
release migration result
operator
timestamp
```

## Backend Smoke Checklist

Health:

```powershell
Invoke-RestMethod -Uri "https://<production-backend-host>/api/health"
```

Expected:

```text
HTTP 200
status=ok
service=disclosure_automation
```

Digest:

```powershell
Invoke-RestMethod -Uri "https://<production-backend-host>/api/feed/digest/latest?edition=breaking"
```

Expected:

```text
HTTP 200
bounded JSON
edition=breaking
no raw provider/auth/session/request material
```

If production has no approved source data yet, a bounded empty digest is acceptable only if documented and approved in issue #561. Do not run source candidate live polling just to make the UI look full. Do not treat fixture fallback as production data evidence.

## CORS Smoke Checklist

From the intended production frontend origin, verify:

```text
GET /api/health succeeds
GET /api/feed/digest/latest?edition=breaking succeeds
no credentials required
no cookies/tokens/session IDs exposed
no browser CORS error
```

If testing manually in browser devtools, record only status and bounded response facts. Do not screenshot secrets or headers containing sensitive material.

## Frontend Promotion Checklist

Do not promote frontend config until backend smoke passes.

Before changing frontend config, record:

```text
current frontend config commit
current frontend API base
target frontend API base
configVersion
rollback commit
```

After config promotion:

```text
GitHub Pages deploy succeeds
public frontend loads
configVersion marker matches expected version
Backend ok visible
digest renders bounded items or documented bounded empty state
no fatal console error
```

## Public Web Smoke

Run:

```text
GitHub Actions -> GlobalPulse public web smoke -> Run workflow
```

Inputs:

```text
pages_url: production or staging frontend URL
backend_url: production backend URL
edition: breaking
```

Record:

```text
workflow run id
pages status
config status
health status
digest status
digest item_count
fallback_to_fixture
forbidden fragment check
artifact name
```

## Rollback Checklist

Rollback decision triggers:

```text
release migration failure
health failure
digest failure
CORS failure
frontend config mismatch
fatal browser rendering error
unexpected public response shape
secret/raw material exposure
```

Backend rollback:

```text
restore previous backend release/image if supported by platform
or deploy previous known-good commit
verify /api/health
verify /api/feed/digest/latest?edition=breaking
```

Frontend rollback:

```text
restore previous config commit
wait for Pages deploy
verify configVersion
verify browser smoke
```

If a database migration cannot be reversed safely, prefer a documented forward fix and keep frontend pointing at the previous backend/config until the bounded smoke passes.

## Post-Deployment Record

Create a docs-only PR:

```text
Record GlobalPulse production deployment smoke
```

Record:

```text
backend app
backend URL
frontend URL
commit SHA
deployment timestamp
health result
digest result
CORS result
public web smoke workflow run id
browser smoke result
rollback readiness
known limitations
```

## Guardrails

```text
Do not print secrets.
Do not reuse staging DB as production by accident.
Do not enable production scheduled polling in deployment smoke.
Do not set source candidates active=true without separate approval.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of deployment smoke.
Do not claim source coverage is complete from latest-window feeds.
Do not start JP live polling before issue #339 is resolved.
```

## Next Gate

Before actual production deployment, decide:

```text
production backend app name
production Postgres/database policy
production frontend URL/domain
production CORS allowed origins
whether public Pages remains staging or becomes production
```
