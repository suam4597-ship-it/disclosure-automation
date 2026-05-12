# GlobalPulse Production CORS Smoke Contract Template

Date: 2026-05-12 KST

This document is a template for the future production CORS smoke contract.

It is documentation-only and not executable as approval. It does not create production infrastructure, provision databases, set secrets, deploy production, change backend CORS runtime behavior, change frontend config, change routes or public API response shapes, enable production scheduled polling, promote sources, set candidate sources `active=true`, add public poll UI, add audit UI, or add public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PRODUCTION_CORS_SMOKE_CONTRACT_TEMPLATE_RECORDED
APPROVED_ORIGINS_REQUIRED_BEFORE_EXECUTION
PRODUCTION_BACKEND_SMOKE_REQUIRED_BEFORE_FRONTEND_PROMOTION
PRODUCTION_SCHEDULED_POLLING_STILL_DISABLED
```

## Current Status

```text
production backend: not created
production frontend URL: not approved
production CORS allowed origins: not approved
production deployment approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
operator approval intake packet: globalpulse_operator_approval_intake_packet.md
```

This template becomes an executable smoke contract only after issue #561 records approved frontend and backend origins.

## Required Approved Values

Fill these values from issue #561 before running production CORS smoke:

```text
FRONTEND_ORIGIN:
BACKEND_ORIGIN:
BACKEND_HEALTH_URL:
BACKEND_DIGEST_URL:
CORS_ALLOWED_ORIGINS:
ALLOW_CREDENTIALS:
ALLOW_WILDCARD_CORS_FOR_PUBLIC_READONLY_FEED:
QUERY_PARAM_OVERRIDE_POLICY:
PRODUCTION_CONFIG_VERSION:
ROLLBACK_OWNER:
SMOKE_OPERATOR:
```

Do not include secret values in this contract.

## Expected Production CORS Policy

The current backend CORS plug reflects allowed origins from `CORS_ALLOWED_ORIGINS`.

Production should record one of these policies explicitly:

```text
Option A: allow only the approved production frontend origin
Option B: allow the approved production frontend origin and the staging Pages origin
Option C: allow wildcard CORS only for a separately accepted public-readonly feed policy
```

Recommended initial production policy:

```text
allow credentials: false
allow methods: GET,POST,OPTIONS
allow headers: accept,content-type
allow origins: approved explicit origins, not wildcard, unless separately accepted
```

## Smoke Requests

### Health From Approved Origin

```powershell
$Backend = "<approved-production-backend-origin>"
$Origin = "<approved-production-frontend-origin>"
$response = Invoke-WebRequest `
  -UseBasicParsing `
  -Uri "$Backend/api/health" `
  -Headers @{ Origin = $Origin } `
  -TimeoutSec 20

$response.StatusCode
$response.Headers["Access-Control-Allow-Origin"]
$response.Content
```

Expected:

```text
status: 200
Access-Control-Allow-Origin: <approved-production-frontend-origin>
body.status: ok
no cookies required
no secret/auth/session/raw provider material exposed
```

### Digest From Approved Origin

```powershell
$Backend = "<approved-production-backend-origin>"
$Origin = "<approved-production-frontend-origin>"
$response = Invoke-WebRequest `
  -UseBasicParsing `
  -Uri "$Backend/api/feed/digest/latest?edition=breaking" `
  -Headers @{ Origin = $Origin } `
  -TimeoutSec 20

$json = $response.Content | ConvertFrom-Json
$response.StatusCode
$response.Headers["Access-Control-Allow-Origin"]
$json.edition
$json.item_count
$json.metadata.fallback_to_fixture
```

Expected:

```text
status: 200
Access-Control-Allow-Origin: <approved-production-frontend-origin>
edition: breaking
item_count: bounded integer or approved empty state
metadata.fallback_to_fixture: false unless explicitly documented otherwise
no backend digest JSON response shape change
no secret/auth/session/raw provider material exposed
```

### Optional Preflight Check

Use this only when the browser path requires preflight.

```powershell
$Backend = "<approved-production-backend-origin>"
$Origin = "<approved-production-frontend-origin>"
$response = Invoke-WebRequest `
  -UseBasicParsing `
  -Method OPTIONS `
  -Uri "$Backend/api/feed/digest/latest?edition=breaking" `
  -Headers @{
    Origin = $Origin
    "Access-Control-Request-Method" = "GET"
    "Access-Control-Request-Headers" = "accept"
  } `
  -TimeoutSec 20

$response.StatusCode
$response.Headers["Access-Control-Allow-Origin"]
$response.Headers["Access-Control-Allow-Methods"]
$response.Headers["Access-Control-Allow-Headers"]
```

Expected:

```text
status: 204
Access-Control-Allow-Origin: <approved-production-frontend-origin>
Access-Control-Allow-Methods: includes GET and OPTIONS
Access-Control-Allow-Headers: includes accept
```

## Forbidden Results

Stop promotion if any of these appear:

```text
Access-Control-Allow-Origin points to an unapproved origin
credentials are required for public health/digest reads
set-cookie appears in public smoke responses
authorization/token/session/private material appears in response body
raw provider payload appears in public digest response
backend digest JSON response shape changes for CORS only
production scheduled polling is enabled just to populate the digest
candidate sources are set active=true without source-specific approval
```

## Browser Smoke

After backend CORS passes, browser smoke should verify:

```text
production frontend loads
runtime config points to approved production backend
health card shows backend ok
digest cards render or show approved bounded-empty fallback
console has no fatal CORS/fetch errors
query-param override policy matches approval
```

## Rollback Check

Before frontend promotion, record:

```text
previous frontend config commit
previous backend deploy/release
previous CORS_ALLOWED_ORIGINS value class, not secret values
rollback owner
rollback smoke command
```

Rollback success criteria:

```text
frontend returns to previous approved API base
backend health remains 200
digest endpoint remains bounded
no production scheduled polling change is needed
```

## Next PR Mapping

When issue #561 contains approved origins:

```text
next PR: Record GlobalPulse production CORS smoke contract
source document: this template
runtime changes: none
required values: approved frontend/backend origins and CORS policy
```

When production backend exists and smoke passes:

```text
next PR: Record GlobalPulse production backend CORS smoke
runtime changes: none unless a separate CORS fix PR is required
```

If CORS smoke fails:

```text
next PR: Fix production CORS boundary
scope: focused backend CORS config/runtime fix
tests: focused CORS contract tests
source promotion: still blocked
production scheduled polling: still disabled
```

## Guardrails

```text
Do not run this as production evidence before origins are approved.
Do not paste secrets.
Do not enable production scheduled polling for CORS smoke.
Do not change public digest JSON response shape for CORS smoke.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not set candidate sources active=true.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```
