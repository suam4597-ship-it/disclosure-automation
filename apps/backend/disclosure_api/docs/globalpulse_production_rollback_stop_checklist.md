# GlobalPulse Production Rollback Stop Checklist

Date: 2026-05-12 KST

This document defines the stop, rollback, and fix-forward decision checklist for a future GlobalPulse production backend/frontend promotion.

This is docs-only. It does not create production infrastructure, provision databases, set secrets, deploy production, change frontend config, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, promote source candidates, add public poll UI, add audit UI, or add public Source Health UI.

## Status

```text
PRODUCTION_ROLLBACK_STOP_CHECKLIST_ADDED
PRODUCTION_INFRA_NOT_CREATED
PRODUCTION_FRONTEND_CONFIG_NOT_PROMOTED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SOURCE_CANDIDATES_NOT_PROMOTED
```

## Use This Before

Use this checklist before executing any future production deployment or frontend promotion command.

It complements:

```text
globalpulse_production_deployment_runbook.md
globalpulse_production_fly_command_templates.md
globalpulse_frontend_production_config_templates.md
globalpulse_production_bounded_empty_digest_policy.md
globalpulse_production_cors_smoke_contract_template.md
```

## Required Operator Values

Do not start production work unless issue #561 records:

```text
approved production backend app name
approved production database policy
approved production frontend URL/domain plan
approved CORS origins
rollback owner
incident contact/process
first production digest empty-state decision
```

Source-by-source production promotion remains separate and must be recorded in issue #565.

## Stop Triggers

Stop the production rollout immediately if any of these occur:

```text
approval values are missing or ambiguous
secret values appear in logs, docs, PRs, or issue comments
staging DATABASE_URL is about to be reused as production
production app/database target does not match approved values
release migration fails
/api/health fails or returns an unexpected service/status
/api/feed/digest/latest?edition=breaking fails
digest response exposes raw provider/auth/session/request/private material
digest response shape differs from the bounded public contract
digest is empty without explicit empty-state approval
fixture fallback is observed and presented as production data
CORS from approved frontend origin fails
frontend configVersion does not match the intended production config
browser smoke shows a fatal rendering or console failure
public Pages points at an unapproved backend
scheduled production polling is enabled before separate approval
candidate source active=true appears without source-specific approval
```

When a stop trigger fires, do not continue to the next checklist step just to complete the deployment. Record the trigger, preserve bounded logs, and choose rollback or forward fix.

## Stop Record

Record only bounded facts:

```text
timestamp
operator
commit SHA
backend app
frontend URL
failed checklist step
HTTP status
bounded response facts
workflow run id if available
rollback owner decision
```

Do not record:

```text
secret values
DATABASE_URL
SECRET_KEY_BASE
cookies
session IDs
authorization headers
raw provider payloads beyond bounded excerpts
private request/auth material
```

## Rollback Options

Backend rollback options:

```text
restore previous known-good Fly release/image if available
deploy previous known-good commit if image rollback is unavailable
keep frontend pointed at the previous known-good backend/config
verify /api/health after rollback
verify /api/feed/digest/latest?edition=breaking after rollback
```

Frontend rollback options:

```text
revert frontend production config commit
restore previous apiBaseUrl/configVersion
wait for Pages or approved host deployment
verify configVersion
verify backend status display
verify digest bounded empty or bounded item rendering
```

Source/schedule rollback options:

```text
disable the specific production schedule if one was approved and enabled
do not disable unrelated staging observation workflows
do not mutate canonical feed data to hide a rollout failure
do not run extra live polls just to fill a production digest
```

## Forward Fix Conditions

A forward fix is acceptable only when:

```text
the rollback owner explicitly chooses forward fix
the failure is bounded and understood
no secret/private material was exposed
database migration state is safe to continue
the frontend can remain on the previous known-good config until smoke passes
the fix can be verified with health, digest, CORS, and browser smoke
```

If any of those are false, prefer rollback or hold the rollout.

## Bounded Empty Digest Decision

The first production digest may be empty only if issue #561 explicitly approves it.

If the digest is empty:

```text
confirm HTTP 200 bounded JSON
confirm no fixture fallback is claimed as production data
confirm the frontend renders the documented empty state
confirm operator approval for empty first launch
record item_count=0 as accepted empty state, not source success
```

If the digest uses fixture fallback, stop. Fixture fallback is not production data evidence.

## Public Smoke After Rollback Or Fix

After rollback or forward fix, rerun the relevant bounded smoke:

```text
GET /api/health
GET /api/feed/digest/latest?edition=breaking
CORS from approved frontend origin
frontend configVersion check
browser/public web smoke
forbidden raw/private material check
```

Record whether the result is:

```text
ROLLBACK_PASS
FORWARD_FIX_PASS
ROLLBACK_HELD_PENDING_OPERATOR
FORWARD_FIX_HELD_PENDING_OPERATOR
```

## Guardrails

```text
Do not create paid or persistent production infrastructure without explicit approval.
Do not print secrets.
Do not reuse staging DB as production.
Do not enable production scheduled polling during first production smoke.
Do not set candidate sources active=true without source-specific approval.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of production smoke.
Do not claim fixture fallback as live or production success.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Next Gate

This checklist is ready to use once production approval values exist. Until then, continue only safe staging observation, documentation, and bounded contract preparation.
