# GlobalPulse Frontend Runtime Config Promotion Design

Date: 2026-05-11 KST

This document defines the promotion contract for moving the GlobalPulse frontend from staging-backed public smoke toward a production-backed web surface.

This is design-only. It does not change `apps/web`, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, or deployment targets.

## Conclusion

```text
GLOBALPULSE_FRONTEND_RUNTIME_CONFIG_PROMOTION_DESIGNED
STAGING_AND_PRODUCTION_API_BASES_MUST_BE_SEPARATED
QUERY_PARAM_OVERRIDE_REMAINS_SMOKE_ONLY
CONFIG_CACHE_BUSTING_REQUIRED_BEFORE_PRODUCTION_PROMOTION
CORS_ORIGIN_POLICY_REQUIRED_BEFORE_PRODUCTION_PROMOTION
ROLLBACK_PATH_REQUIRED_BEFORE_PRODUCTION_PROMOTION
PRODUCTION_BACKEND_NOT_CREATED_IN_THIS STEP
```

## Current State

```text
frontend host: GitHub Pages
frontend URL: https://suam4597-ship-it.github.io/disclosure-automation/
runtime config file: apps/web/config.js
current default API base: https://globalpulse-backend-staging.fly.dev
override path: ?apiBase=<backend-url>
current backend class: Fly staging
current production backend: not configured
```

The current public Pages URL intentionally points at Fly staging so browser smoke can validate real deployed frontend-to-backend wiring.

That is acceptable for staging smoke, but it should not be treated as a production launch configuration.

## Promotion Model

Use three explicit runtime classes:

```text
local smoke
staging
production
```

Required separation:

```text
local smoke:
  frontend: local static server or Pages with ?apiBase override
  backend: local/mock/Fly staging
  purpose: developer/browser validation

staging:
  frontend: GitHub Pages current public URL
  backend: https://globalpulse-backend-staging.fly.dev
  purpose: public smoke and source candidate observation

production:
  frontend: production URL or production Pages config
  backend: dedicated production backend URL
  purpose: user-facing stable service
```

Production must not silently inherit the staging API base.

## Runtime Config Contract

The production-ready frontend config must make these values obvious:

```text
api_base_url
environment_label
config_version
generated_at or updated_at marker
allowed_override_policy
```

Suggested staged shape:

```javascript
window.GLOBALPULSE_RUNTIME_CONFIG = {
  environment: "staging",
  apiBaseUrl: "https://globalpulse-backend-staging.fly.dev",
  configVersion: "staging-YYYYMMDD-N",
  allowQueryParamOverride: true
};
```

The existing `window.DISCLOSURE_API_BASE_URL` can remain as a compatibility field while the frontend shell is static.

Production should set:

```text
environment: production
allowQueryParamOverride: false or operator-only documented exception
apiBaseUrl: dedicated production backend URL
```

## Query Param Override Policy

Current behavior:

```text
?apiBase=<backend-url> can be used for one-off smoke tests
```

Keep this for staging/browser smoke, but before production decide one of:

```text
Option A: disable query-param override on production URL
Option B: keep it only for non-production Pages URL
Option C: keep it but visibly mark the UI as override mode
```

Recommended:

```text
staging: allow ?apiBase for smoke/debug
production: disable ?apiBase by default
```

Why:

```text
prevents accidental user-facing connection to an untrusted backend
keeps browser smoke flexible
avoids mixing staging and production evidence
```

## CORS Contract

Before production promotion, backend CORS must explicitly record:

```text
staging frontend origin
production frontend origin
local development origin if needed
whether wildcard CORS is acceptable in staging only
```

Production should not rely on wildcard `Access-Control-Allow-Origin: *` unless explicitly accepted for the public readonly feed surface.

At minimum, smoke should record:

```text
GET /api/health from frontend origin succeeds
GET /api/feed/digest/latest?edition=breaking from frontend origin succeeds
no cookies/credentials required
no auth/session/token material exposed
```

## Cache And Invalidation

Static Pages can cache `config.js`, so promotion must include a cache-busting policy.

Acceptable options:

```text
Option A: keep config.js low-cache through hosting headers if platform supports it
Option B: version config file name, for example config.staging.20260511.js
Option C: add a configVersion marker and verify it in public web smoke
```

Recommended first step:

```text
keep config.js filename stable
add configVersion marker
require public web smoke to assert the expected marker before production smoke is recorded
```

## Rollback Contract

Any production config promotion must have an easy rollback:

```text
previous frontend config commit
previous backend image/release
previous backend API base URL
previous CORS origin list
smoke command to prove rollback
```

Rollback smoke:

```text
GET production frontend: 200
GET production config: expected previous configVersion
GET production backend /api/health: 200
GET production digest latest: 200
public browser shows Backend ok
```

## Required Smoke Before Production Config Promotion

Run and record:

```text
GlobalPulse public web smoke workflow: pass
Pages shell: pass
Pages config marker: pass
backend health: pass
backend digest: pass
forbidden public fragments: pass
browser visual smoke: pass or explicitly not-run with reason
```

For production-specific promotion, also require:

```text
production backend URL: recorded
production CORS policy: recorded
production configVersion: recorded
production rollback path: recorded
```

## Suggested PR Sequence

```text
1. Record GlobalPulse public web smoke workflow run.
2. Design GlobalPulse frontend runtime config promotion.  <-- this document
3. Design GlobalPulse production backend deployment.
4. Add configVersion and environment label to staging config.
5. Record staging configVersion public smoke.
6. Create production backend deployment only after design review.
7. Promote frontend config to production backend only after production backend smoke passes.
```

## Guardrails

```text
Do not repoint public Pages to production before production backend exists.
Do not reuse staging DB as production by accident.
Do not enable production scheduled polling in a frontend config PR.
Do not set source candidates active=true in a frontend config PR.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not expose raw provider/auth/session/request material.
```

## Next Gate

The next implementation-level PR should be small:

```text
Add GlobalPulse frontend config version marker
```

It should add only bounded runtime config metadata and tests/smoke checks, not a production backend URL.

Production config promotion templates are recorded separately:

```text
globalpulse_frontend_production_config_templates.md
```
