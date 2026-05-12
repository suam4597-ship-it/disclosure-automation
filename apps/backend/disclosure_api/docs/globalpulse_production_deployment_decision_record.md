# GlobalPulse Production Deployment Decision Record

Date: 2026-05-11 KST

This document records the open decisions required before creating or promoting a production GlobalPulse deployment.

This is decision-record only. It does not create a Fly app, provision a database, set secrets, deploy production, change frontend config, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, or promote source candidates.

## Conclusion

```text
GLOBALPULSE_PRODUCTION_DEPLOYMENT_DECISION_RECORD_ADDED
PRODUCTION_APPROVAL_BLOCKER_STATUS_RECORDED
PRODUCTION_BACKEND_APP_DECISION_PENDING
PRODUCTION_DATABASE_DECISION_PENDING
PRODUCTION_FRONTEND_URL_DECISION_PENDING
PRODUCTION_CORS_POLICY_DECISION_PENDING
PRODUCTION_SOURCE_SCHEDULE_POLICY_PENDING
NO_PRODUCTION_INFRA_CREATED
```

## Current Known Values

```text
public staging frontend: https://suam4597-ship-it.github.io/disclosure-automation/
staging backend: https://globalpulse-backend-staging.fly.dev
staging config version: staging-20260511-1
public web smoke workflow: GlobalPulse public web smoke
public web smoke daily schedule: 17 0 * * *
latest main maintenance smoke run: 25677329262
latest main maintenance smoke result: pass
production approval tracking issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
latest approval blocker status doc: globalpulse_production_approval_blocker_status_20260512.md
```

The public frontend currently uses the Fly staging backend. That is valid for staging smoke and live-source observation, but it is not yet a production deployment decision.

Latest approval status check:

```text
issue #561 state: open
issue #561 comments: 1
issue #565 state: open
issue #565 comments: 1
operator production values provided: no
source promotion approvals provided: no
approval request comments posted: yes
```

## Decisions Needed Before Provisioning

### 1. Production Backend App

Recommended default:

```text
production Fly app: globalpulse-backend-production
production backend URL: https://globalpulse-backend-production.fly.dev
```

Decision required:

```text
APPROVE_CREATE_PRODUCTION_FLY_APP: yes/no
APP_NAME: globalpulse-backend-production or another approved name
REGION: choose Fly primary region
```

Do not create the app until this is explicitly approved because it can create persistent infrastructure and billing surface.

### 2. Production Database

Recommended default:

```text
dedicated production Postgres
do not reuse staging DATABASE_URL
```

Decision required:

```text
APPROVE_CREATE_PRODUCTION_DATABASE: yes/no
DATABASE_PROVIDER: Fly Postgres or another provider
DATABASE_PLAN: smallest acceptable production/staging-safe plan
BACKUP_POLICY: provider default or explicitly configured
RETENTION_POLICY: pending
```

Production must not silently share staging source-candidate observations.

### 3. Production Secrets

Required secret names:

```text
DATABASE_URL
SECRET_KEY_BASE
PHX_HOST
PORT
```

Decision required:

```text
SECRET_OWNER: who sets/rotates production secrets
PHX_HOST: production backend host
PORT: platform-provided or 8080
```

Never paste secret values into docs, PRs, issue comments, terminal logs, screenshots, or handoff notes.

### 4. Production Frontend Surface

Options:

```text
Option A: keep GitHub Pages as staging-only and add a separate production frontend later
Option B: promote the existing GitHub Pages URL to production after production backend smoke
Option C: add a custom domain or another hosting target for production
```

Recommended until production backend exists:

```text
keep current GitHub Pages URL as staging-backed public smoke
do not promote frontend config to production
```

Decision required:

```text
PRODUCTION_FRONTEND_URL: pending
PRODUCTION_CONFIG_VERSION: pending
QUERY_PARAM_OVERRIDE_POLICY: disabled for production or staging-only
```

### 5. CORS Policy

Current staging behavior is sufficient for public smoke. Production requires a recorded policy.

Decision required:

```text
ALLOWED_ORIGINS:
- staging Pages origin
- production frontend origin
- optional local development origin

ALLOW_WILDCARD_CORS_FOR_PUBLIC_READONLY_FEED: yes/no
ALLOW_CREDENTIALS: no unless separately designed
```

Production smoke must prove:

```text
GET /api/health from frontend origin succeeds
GET /api/feed/digest/latest?edition=breaking from frontend origin succeeds
no cookies/tokens/session IDs required
no raw provider/auth/session/request material exposed
```

### 6. Source Schedule Policy

Initial production deployment should not enable production scheduled polling.

Decision required:

```text
PRODUCTION_SCHEDULED_POLLING: disabled for first production backend smoke
APPROVED_PRODUCTION_SOURCES: none until source-by-source approval
```

Staging observation can continue separately for:

```text
SEC baseline
India NSE
EU canary
Denmark DFSA OAM
HKEX
other candidate sources still active=false
```

JP remains blocked by the source authority decision tracked separately. KR remains deferred until the dedicated backend/source path exists.

## Safe Execution Sequence After Approval

Only after the decisions above are approved:

```text
1. Create production Fly app.
2. Provision dedicated production database.
3. Set production secrets.
4. Deploy backend to production app.
5. Run release migrations.
6. Smoke /api/health.
7. Smoke /api/feed/digest/latest?edition=breaking.
8. Smoke CORS from intended frontend origin.
9. Record production backend smoke.
10. Promote frontend config only after backend smoke passes.
11. Run public web smoke against production values.
12. Record production frontend/backend smoke.
```

Command templates for the Fly.io path are recorded in:

```text
globalpulse_production_fly_command_templates.md
```

The operator-facing approval intake packet is recorded in:

```text
globalpulse_operator_approval_intake_packet.md
```

## Values To Bring From The Operator

The operator should provide these values without secrets:

```text
approved production app name
approved production region
approved production database provider/plan
approved production frontend URL or domain plan
approved CORS origin list
approved rollback owner
approved incident contact/process
approval for whether the first production digest may be empty
```

Secret values should be entered directly into the hosting provider or secret manager, not pasted into this repo.

Track those approvals in:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/561
```

## Guardrails

```text
Do not create paid or persistent production infrastructure without explicit approval.
Do not print secrets.
Do not reuse staging DB as production by accident.
Do not enable production scheduled polling in deployment setup.
Do not set candidate sources active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of deployment smoke.
Do not claim latest-window source feeds are complete market coverage.
Do not start JP live polling before the source authority decision is resolved.
```

## Next Gate

The next safe implementation step is not production provisioning yet. It is one of:

```text
record matching scheduled observation runs as they appear
record first daily scheduled public web smoke when event=schedule appears
continue public web smoke daily observation
prepare production Fly app/database creation only after explicit approval
continue source observation window documentation
```
