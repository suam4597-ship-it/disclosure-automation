# GlobalPulse Production Deployment Smoke Record Template

Date: 2026-05-12 KST

This document is a template for a future docs-only PR that records the first GlobalPulse production backend/frontend smoke.

This is template-only. It does not create production infrastructure, provision databases, set secrets, deploy production, change frontend config, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, promote source candidates, add public poll UI, add audit UI, or add public Source Health UI.

## Template Status

```text
PRODUCTION_DEPLOYMENT_SMOKE_RECORD_TEMPLATE_ADDED
PRODUCTION_DEPLOYMENT_NOT_EXECUTED
PRODUCTION_FRONTEND_CONFIG_NOT_PROMOTED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SOURCE_CANDIDATES_NOT_PROMOTED
```

## Source Approval Records

Before using this template, link the approval records:

```text
production approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
source promotion approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/565
approval comment IDs:
approval timestamp:
operator:
```

Do not include secret values.

## Deployment Facts

Record:

```text
production backend app:
production backend URL:
production frontend URL:
production database policy:
production configVersion:
deployed commit SHA:
backend release/image id:
frontend config commit:
deployment timestamp:
operator:
rollback owner:
```

## Backend Smoke Result

Health:

```text
GET /api/health status:
health.status:
health.service:
health.phase:
bounded raw/private material check: pass/fail
```

Digest:

```text
GET /api/feed/digest/latest?edition=breaking status:
digest edition:
digest item_count:
metadata.fallback_to_fixture:
generated_by:
bounded empty digest approved: yes/no/not-applicable
public response shape unchanged: pass/fail
raw provider/auth/session/request/private material check: pass/fail
```

If `item_count=0`, also record:

```text
FIRST_PRODUCTION_DIGEST_EMPTY_OK:
empty-state approval source:
frontend empty-state smoke result:
```

## CORS Smoke Result

Record:

```text
frontend origin:
backend origin:
GET /api/health from frontend origin:
GET /api/feed/digest/latest?edition=breaking from frontend origin:
credentials required: yes/no
cookies/tokens/session IDs exposed: yes/no
browser CORS error: yes/no
allowed origins matched approval: yes/no
```

## Frontend Smoke Result

Record:

```text
frontend URL status:
config.js status:
configVersion:
apiBaseUrl:
backend status display:
digest rendering:
empty-state rendering if applicable:
fatal console error:
raw JSON dump visible:
secret/token/session/private material visible:
public poll UI visible:
audit UI visible:
public Source Health UI visible:
```

## Public Web Smoke Workflow

Record:

```text
workflow: GlobalPulse public web smoke
workflow run id:
pages_url:
backend_url:
edition:
pages status:
config status:
health status:
digest status:
digest item_count:
fallback_to_fixture:
artifact name:
```

If the workflow cannot represent an approved empty digest, record that limitation and use `globalpulse_production_frontend_empty_state_smoke_checklist.md` for browser evidence.

## Scheduled Polling And Source State

Record:

```text
production scheduled polling enabled: yes/no
approved production sources:
candidate sources active=true without approval: yes/no
manual live poll run during deployment smoke: yes/no
fixture fallback claimed as production data: yes/no
```

Expected first production smoke default:

```text
production scheduled polling enabled: no
approved production sources: none unless issue #565 has explicit source approvals
manual live poll run during deployment smoke: no
fixture fallback claimed as production data: no
```

## Result Labels

Use only labels that match the evidence:

```text
PRODUCTION_BACKEND_HEALTH_PASS
PRODUCTION_DIGEST_BOUNDED_PASS
PRODUCTION_DIGEST_EMPTY_STATE_APPROVED
PRODUCTION_CORS_PASS
PRODUCTION_FRONTEND_CONFIG_PASS
PRODUCTION_PUBLIC_WEB_SMOKE_PASS
PRODUCTION_ROLLBACK_READY
PRODUCTION_SMOKE_HELD_PENDING_FIX
PRODUCTION_SMOKE_HELD_PENDING_OPERATOR
```

Do not use:

```text
PRODUCTION_SOURCE_POLLING_READY
PRODUCTION_SOURCE_COVERAGE_COMPLETE
PRODUCTION_SCHEDULED_POLLING_ENABLED
```

unless those facts are separately approved and proven.

## Failure Or Hold Record

If any smoke fails, record:

```text
failed step:
bounded failure facts:
rollback stop checklist used: yes/no
rollback decision:
forward-fix decision:
next owner:
```

Use:

```text
globalpulse_production_rollback_stop_checklist.md
```

## Guardrails

```text
Do not print secrets.
Do not reuse staging DB as production.
Do not enable production scheduled polling during first production smoke.
Do not set candidate sources active=true without source-specific approval.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of deployment smoke.
Do not claim fixture fallback as production data.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Future PR Title

When production smoke actually runs, use a docs-only PR title like:

```text
Record GlobalPulse production deployment smoke
```
