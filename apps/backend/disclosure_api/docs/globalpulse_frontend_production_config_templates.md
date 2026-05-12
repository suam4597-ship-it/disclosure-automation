# GlobalPulse Frontend Production Config Templates

Date: 2026-05-12 KST

This document provides templates for a future production frontend runtime-config promotion after the production backend has passed smoke.

This is template-only. It does not change `apps/web/config.js`, deploy GitHub Pages, change backend runtime behavior, change routes, change public API response shapes, enable production scheduled polling, or promote source candidates.

## Conclusion

```text
GLOBALPULSE_FRONTEND_PRODUCTION_CONFIG_TEMPLATES_ADDED
COMMANDS_ARE_NOT_EXECUTED
PRODUCTION_BACKEND_SMOKE_REQUIRED_FIRST
PRODUCTION_APPROVAL_ISSUE_REQUIRED_FIRST
FRONTEND_CONFIG_NOT_PROMOTED
```

## Required Approval First

Do not promote frontend config until the production approval issue is complete:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/561
```

Do not promote frontend config until the production backend smoke passes and is recorded.

Minimum required values:

```text
production frontend URL
production backend URL
production configVersion
production CORS allowed origins
query-param override policy
rollback commit
browser smoke operator
```

## Current Staging Config Shape

Current public staging shape:

```text
frontend URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend URL: https://globalpulse-backend-staging.fly.dev
environment: staging
configVersion: staging-20260511-1
allowQueryParamOverride: true
```

Production config must not silently inherit staging.

## Suggested Production Config Shape

Template only:

```javascript
window.GLOBALPULSE_RUNTIME_CONFIG = {
  environment: "production",
  apiBaseUrl: "https://<approved-production-backend-host>",
  configVersion: "production-YYYYMMDD-N",
  allowQueryParamOverride: false,
  regionLabels: {
    greater_china: "Greater China",
    eu_north: "Northern Europe",
    eu_central: "Central Europe",
    eu_south: "Southern Europe"
  }
};

window.DISCLOSURE_API_BASE_URL = window.GLOBALPULSE_RUNTIME_CONFIG.apiBaseUrl;
```

Compatibility note:

```text
window.DISCLOSURE_API_BASE_URL may remain while the static frontend shell still reads it.
```

## Pre-Promotion Checks

Before editing frontend config, record:

```text
current commit
current configVersion
current backend URL
target backend URL
production backend health smoke result
production backend digest smoke result
production CORS smoke result
rollback commit
```

Required backend smoke:

```text
GET production /api/health: 200
GET production /api/feed/digest/latest?edition=breaking: 200
public response safety check: pass
```

## Branch Template

```powershell
git fetch origin --prune
git checkout phase0-foundation
git pull --ff-only origin phase0-foundation
git switch -c codex/promote-globalpulse-frontend-production-config-v1
```

Edit only:

```text
apps/web/config.js
```

Optionally add/update a docs-only smoke result after deployment.

## Local Static Check

From repo root:

```powershell
node --check apps/web/config.js
node --check apps/web/script.js
```

If using a local static server:

```powershell
cd apps/web
python -m http.server 8781
```

Check:

```text
http://127.0.0.1:8781/
GlobalPulse shell renders
configVersion visible in fetched config.js
no fatal console errors
```

## Pull Request Template

Title:

```text
Promote GlobalPulse frontend config to production backend
```

PR body must record:

```text
production backend URL
production frontend URL
configVersion
production backend smoke result
CORS smoke result
rollback commit
query-param override policy
```

Guardrail text:

```text
This PR changes only frontend runtime config.
It does not enable production scheduled polling.
It does not set source candidates active=true.
It does not change backend digest JSON response shape.
```

## GitHub Pages Deploy Check

After merge, wait for the Pages deploy workflow.

Check:

```text
Deploy Phase 0 web to GitHub Pages: success
public Pages URL returns 200
config.js returns 200
config.js contains expected production configVersion
```

If Pages environment protection blocks deploy:

```text
do not change backend
resolve GitHub Pages environment protection
rerun deploy
record blocked status if unresolved
```

## Public Web Smoke

Run:

```text
GitHub Actions -> GlobalPulse public web smoke
```

Inputs:

```text
pages_url: <approved-production-frontend-url>
backend_url: <approved-production-backend-url>
edition: breaking
```

Record:

```text
workflow run id
pages status
config status
configVersion
health status
digest status
digest item_count
fallback_to_fixture
artifact id
Node/runtime warnings if any
```

## Browser Smoke

Check:

```text
GlobalPulse header visible
Backend ok visible
digest region sections render
operator Source Health link present
no CORS/fetch fatal error
no raw JSON dump
no secret/token/session material
```

If production digest is intentionally empty at launch, record the approved empty-state policy from issue #561.

Use this companion checklist for the empty-state browser/public smoke:

```text
globalpulse_production_frontend_empty_state_smoke_checklist.md
```

## Rollback Template

If frontend config promotion fails:

```powershell
git revert <frontend-config-promotion-commit>
git push origin phase0-foundation
```

Then verify:

```text
Pages deploy succeeds
configVersion returns to previous value
public web smoke passes against previous backend
browser renders without fatal errors
```

## Guardrails

```text
Do not promote frontend config before production backend smoke passes.
Do not rely on staging backend as production.
Do not leave query-param override enabled for production unless explicitly approved.
Do not enable production scheduled polling in a frontend config PR.
Do not set source candidates active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not print secrets.
```
