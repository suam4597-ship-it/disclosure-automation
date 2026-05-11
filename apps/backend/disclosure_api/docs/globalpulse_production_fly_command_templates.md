# GlobalPulse Production Fly Command Templates

Date: 2026-05-12 KST

This document provides command templates for a future Fly.io production backend deployment after the production approval checklist is complete.

This is template-only. It does not create Fly apps, provision databases, set secrets, deploy production, change frontend config, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, or promote source candidates.

## Conclusion

```text
GLOBALPULSE_PRODUCTION_FLY_COMMAND_TEMPLATES_ADDED
COMMANDS_ARE_NOT_EXECUTED
PRODUCTION_APPROVAL_ISSUE_REQUIRED_FIRST
SECRETS_MUST_BE_SET_OUTSIDE_DOCS
PRODUCTION_INFRA_NOT_CREATED
```

## Required Approval First

Do not run these commands until the production approval issue is complete:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/561
```

Minimum approved values required:

```text
production app name
production region
production database provider/plan
production PHX_HOST
production frontend URL/origin
production CORS policy
secret owner
rollback owner
first production digest empty-state policy
```

## Suggested Variables

PowerShell template:

```powershell
$AppName = "globalpulse-backend-production"
$Region = "<approved-region>"
$ProductionHost = "globalpulse-backend-production.fly.dev"
$FrontendOrigin = "<approved-production-frontend-origin>"
```

Do not paste secret values into the terminal history if your environment records history in a shared place.

## Create Production App

Template only:

```powershell
fly apps create $AppName --org personal
```

If the organization is not `personal`, use the approved Fly organization.

Record after running:

```text
app name
organization
primary region
operator
timestamp
```

## Provision Or Attach Production Database

Use the approved database provider and plan. If using Fly Postgres, use an approved command from the current Fly CLI docs and record the resulting attachment name.

Template shape:

```powershell
fly postgres create --name "<approved-db-name>" --region $Region
fly postgres attach "<approved-db-name>" --app $AppName
```

Guardrail:

```text
do not attach staging Postgres as production by accident
do not paste DATABASE_URL into docs, PRs, issues, or screenshots
```

## Set Production Secrets

Template shape:

```powershell
fly secrets set SECRET_KEY_BASE="<secret-value>" PHX_HOST="$ProductionHost" --app $AppName
```

If `DATABASE_URL` is not attached automatically, set it through the provider/secret manager without printing it.

Never record:

```text
DATABASE_URL value
SECRET_KEY_BASE value
tokens
credentials
connection strings
```

## Deploy Backend

Template:

```powershell
cd apps/backend/disclosure_api
fly deploy --remote-only --app $AppName
```

Required checks:

```text
release command/migration: success
deployed commit SHA: recorded
release/image id: recorded
```

If migration fails:

```text
stop
do not promote frontend config
decide rollback or forward fix
record failure without secrets
```

## Backend Smoke

Health:

```powershell
Invoke-RestMethod -Uri "https://$ProductionHost/api/health"
```

Expected:

```text
HTTP 200
status=ok
service=disclosure_automation
```

Digest:

```powershell
Invoke-RestMethod -Uri "https://$ProductionHost/api/feed/digest/latest?edition=breaking"
```

Expected:

```text
HTTP 200
bounded JSON
edition=breaking
no raw provider/auth/session/request material
```

An empty production digest can be acceptable only if issue #561 explicitly approves that launch state.

## CORS Smoke

From browser devtools or a controlled local page at the approved frontend origin:

```text
GET https://<production-host>/api/health
GET https://<production-host>/api/feed/digest/latest?edition=breaking
```

Expected:

```text
no CORS error
no credentials required
no cookies/tokens/session IDs exposed
```

## Frontend Config Promotion

Only after backend and CORS smoke pass:

```text
update production frontend config
set environment=production
set production apiBaseUrl
set configVersion
decide query-param override behavior
```

Recommended production default:

```text
allowQueryParamOverride=false
```

Do not change frontend config in the same step as failed backend smoke.

## Public Web Smoke

Run the GitHub Actions workflow:

```text
GlobalPulse public web smoke
```

Inputs:

```text
pages_url: <production-frontend-url>
backend_url: https://<production-host>
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
artifact id
```

## Rollback Template

Backend rollback options:

```powershell
fly releases --app $AppName
fly deploy --remote-only --app $AppName --image "<previous-known-good-image>"
```

If image rollback is not available, deploy the previous known-good commit.

Frontend rollback:

```text
revert frontend config commit
wait for Pages deploy
run public web smoke again
```

Rollback smoke:

```text
GET /api/health: 200
GET /api/feed/digest/latest?edition=breaking: bounded response
public frontend: no fatal fetch/CORS/rendering error
```

## Guardrails

```text
Do not run these commands before issue #561 approval.
Do not print secrets.
Do not reuse staging DB as production.
Do not enable production scheduled polling during first backend smoke.
Do not set source candidates active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies during deployment smoke.
```
