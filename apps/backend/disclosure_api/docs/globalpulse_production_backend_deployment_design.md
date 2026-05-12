# GlobalPulse Production Backend Deployment Design

Date: 2026-05-11 KST

This document defines the production backend deployment contract for GlobalPulse.

This is design-only. It does not create a production app, provision a database, add secrets, change frontend config, change routes, change public API response shapes, enable production scheduled polling, or promote any source candidates.

## Conclusion

```text
GLOBALPULSE_PRODUCTION_BACKEND_DEPLOYMENT_DESIGNED
DEDICATED_PRODUCTION_BACKEND_REQUIRED
DEDICATED_PRODUCTION_DATABASE_REQUIRED
STAGING_DATABASE_MUST_NOT_BE_REUSED_AS_PRODUCTION
PRODUCTION_CORS_POLICY_REQUIRED
PRODUCTION_SECRET_POLICY_REQUIRED
PRODUCTION_SMOKE_AND_ROLLBACK_REQUIRED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED_BY_THIS DESIGN
```

## Current State

```text
staging backend: https://globalpulse-backend-staging.fly.dev
staging app: globalpulse-backend-staging
staging database: Fly Postgres staging attachment
public frontend: GitHub Pages
public frontend default backend: Fly staging
production backend: not created
production database: not created
production frontend config: not created
```

The staging app is suitable for public smoke and source-candidate observation. It should not be silently promoted into production without a separate deployment decision.

## Recommended Production Shape

Use a separate backend app:

```text
production app candidate: globalpulse-backend-production
production host candidate: https://globalpulse-backend-production.fly.dev
production frontend origin: pending
production database: dedicated Postgres
production source schedules: disabled until source-by-source approval
```

Why separate:

```text
keeps staging candidate polling from contaminating production data
allows safe rollback without breaking ongoing staging observations
keeps CORS and secrets environment-specific
supports production retention/backup policy independently
```

## Required Environment Variables

Production must define these without printing secret values in logs or docs:

```text
DATABASE_URL
SECRET_KEY_BASE
PHX_HOST
PORT
```

Recommended production values:

```text
PHX_HOST=globalpulse-backend-production.fly.dev or custom backend domain
PORT=8080 or platform-provided port
MIX_ENV=prod
```

Do not copy staging secrets into production by hand unless there is an explicit rotation plan.

## Database Policy

Production requires:

```text
dedicated database
migration runbook
backup/restore note
retention note
manual seed/poll policy
rollback behavior if migration fails
```

Production must not reuse:

```text
staging DATABASE_URL
staging source candidate observations as production evidence
local developer database
```

## Source Polling Policy

Initial production backend deployment should verify app health and readonly digest behavior only.

Do not enable:

```text
production scheduled polling
new active=true source candidates
HKEX scheduled production polling
EU scheduled production polling
India scheduled production polling
JP live polling
KR source implementation
```

Allowed first production smoke:

```text
GET /api/health
GET /api/feed/digest/latest?edition=breaking
bounded empty or seeded digest response if no production source data exists
```

If a production smoke needs data, use a documented bounded seed or a one-off manually approved poll. Do not imply scheduled production source approval.

## CORS Policy

Production must record allowed origins before frontend promotion:

```text
GitHub Pages staging origin: https://suam4597-ship-it.github.io
future production frontend origin: pending
local development origin: optional
```

If the feed remains public readonly, wildcard CORS may be acceptable only if explicitly recorded.

Required smoke:

```text
frontend origin can call /api/health
frontend origin can call /api/feed/digest/latest?edition=breaking
no credentials required
no auth/session/token/raw provider material exposed
```

## Deployment Flow

Suggested safe sequence:

```text
1. Create production backend app.
2. Provision dedicated production Postgres.
3. Set production secrets.
4. Deploy current backend image/code.
5. Run release migrations.
6. Verify /api/health.
7. Verify /api/feed/digest/latest?edition=breaking.
8. Verify CORS from intended frontend origin.
9. Record production backend smoke.
10. Only then consider frontend config promotion.
```

## Rollback Flow

Record before promotion:

```text
previous deployed backend release/image
previous env var set
database migration rollback or forward-fix plan
frontend config rollback commit
smoke command after rollback
```

Minimum rollback smoke:

```text
GET /api/health: 200
GET /api/feed/digest/latest?edition=breaking: bounded response
public frontend no fatal fetch/CORS errors
```

## Monitoring Before Launch

Before a production frontend points to this backend, add or explicitly defer:

```text
health endpoint uptime check
digest freshness check
source poll failure check
database storage/connection check
manual incident contact/process
rollback decision owner
```

Avoid alert noise until the checks have clear owners.

## Production Promotion Gates

Do not call production ready until all are recorded:

```text
production backend URL
production DB policy
production secrets configured
release migration success
health smoke pass
digest smoke pass
CORS smoke pass
rollback path
frontend configVersion smoke
source schedule policy
```

## Guardrails

```text
Do not create production secrets in docs.
Do not print secret values in logs.
Do not reuse staging DB as production by accident.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not change public digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not start JP live polling before issue #339 is resolved.
```

## Next Gate

After this design, the next safe PR is:

```text
Add GlobalPulse production deployment runbook
```

That runbook should be a concrete operator checklist, not a deployment implementation.
