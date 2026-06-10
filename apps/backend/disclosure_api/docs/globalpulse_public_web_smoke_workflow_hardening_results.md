# GlobalPulse Public Web Smoke Workflow Hardening Results

Date: 2026-05-12 KST

This document records the workflow hardening result after reviewing the GlobalPulse website deployment workflow before the next scheduled public web smoke run.

This is documentation-only. It does not change frontend runtime code, backend runtime behavior, routes, public API response shapes, production infrastructure, production scheduled polling, source activation, source promotion, public poll UI, audit UI, or public Source Health UI.

## Result

```text
PUBLIC_WEB_SMOKE_PRODUCTION_READY_INPUTS_ADDED
PAGES_DEPLOY_STATIC_JS_SYNTAX_CHECK_ADDED
SCHEDULED_STAGING_PUBLIC_SMOKE_DEFAULTS_UNCHANGED
PRODUCTION_DEPLOYMENT_NOT_STARTED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SOURCE_CANDIDATES_NOT_PROMOTED
```

## PR

```text
workflow hardening PR: #607 Harden GlobalPulse public web smoke workflow
workflow hardening merge commit: 9ff91b8d40cd34c797e7573d1978813294717d57
result record PR: #608 Record GlobalPulse public web smoke workflow hardening
result record merge commit: 4955d5e0df91143e2be94dc953561f44b1007f82
```

## What Changed

Pages deployment now checks static frontend JavaScript syntax before uploading the Pages artifact:

```text
node --check apps/web/config.js
node --check apps/web/script.js
node --check extracted inline script from apps/web/index.html
```

The public web smoke workflow now accepts future production smoke inputs:

```text
expected_environment
expected_config_version
expected_api_base_url
expected_allow_query_param_override
allow_empty_digest
```

The scheduled default remains staging-backed:

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
backend_url: https://globalpulse-backend-staging.fly.dev
edition: breaking
expected_environment: staging
expected_config_version: staging-20260511-1
expected_api_base_url: https://globalpulse-backend-staging.fly.dev
expected_allow_query_param_override: true
allow_empty_digest: false
```

## GitHub Actions Result

For merge commit `9ff91b8d40cd34c797e7573d1978813294717d57`:

```text
Deploy Phase 0 web to GitHub Pages: success
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

The Pages deploy job included:

```text
Check static web JavaScript syntax: success
Deploy to GitHub Pages: success
```

## Public Surface Check

Post-merge public checks:

```text
GET public Pages /: 200
GET public Pages /config.js: 200
GET Fly staging /api/health: 200
GET Fly staging /api/feed/digest/latest?edition=breaking: 200
health.status: ok
health.service: disclosure_automation
digest.edition: breaking
digest.item_count: 12
digest.metadata.fallback_to_fixture: false
```

This confirms the default staging-backed public web smoke contract still holds after the workflow hardening.

## Production Use Boundary

The production-ready inputs do not approve production.

Use them only after issue #561 provides approved production values:

```text
approved production frontend URL
approved production backend URL
approved production configVersion
approved apiBaseUrl
approved query-param override policy
approved first production empty digest decision if allow_empty_digest=true
```

The scheduled staging run should keep `allow_empty_digest=false`.

## Guardrails

```text
Do not treat workflow parameterization as production approval.
Do not repoint public Pages to an unapproved production backend.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as production data.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```
