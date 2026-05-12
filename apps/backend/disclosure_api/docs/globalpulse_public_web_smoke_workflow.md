# GlobalPulse Public Web Smoke Workflow

Date: 2026-05-11 KST

This document records the public web smoke workflow for validating the deployed GlobalPulse GitHub Pages shell against the Fly staging backend.

This is a workflow/smoke addition. It does not change frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, or production deployment.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_ADDED
PUBLIC_PAGES_SHELL_CONTRACT_CHECK_ADDED
PUBLIC_PAGES_CONFIG_CONTRACT_CHECK_ADDED
FLY_STAGING_HEALTH_CHECK_ADDED
FLY_STAGING_DIGEST_CHECK_ADDED
PUBLIC_RESPONSE_FORBIDDEN_FRAGMENT_CHECK_ADDED
WORKFLOW_DISPATCH_ONLY
PRODUCTION_DEPLOYMENT_NOT_CHANGED
```

## Workflow

```text
.github/workflows/globalpulse-public-web-smoke.yml
```

Inputs:

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
backend_url: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

Trigger:

```text
workflow_dispatch
daily schedule: 17 0 * * *
```

The workflow was manual-first until the first dispatch run passed. The daily schedule is intentionally lightweight and validates only public Pages + Fly staging readonly endpoints.

The workflow also opts JavaScript actions into Node.js 24 with:

```text
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true
```

## Checks

Public Pages shell:

```text
GET pages_url: 2xx
contains GlobalPulse
contains config.js
contains Source Health
contains apiBase override marker
```

Public Pages config:

```text
GET pages_url/config.js: 2xx
contains window.DISCLOSURE_API_BASE_URL
contains https://globalpulse-backend-staging.fly.dev
contains greater_china
contains eu_north/eu_central/eu_south labels
```

Fly staging health:

```text
GET backend_url/api/health: 2xx
status: ok
service: disclosure_automation
```

Fly staging digest:

```text
GET backend_url/api/feed/digest/latest?edition=breaking: 2xx
edition: breaking
items: non-empty
metadata.fallback_to_fixture: false
```

Forbidden public fragments:

```text
authorization
cookie
set-cookie
secret
token
session_id
raw_provider
raw_auth
```

## Artifact

The workflow uploads:

```text
pages.html
config.js
health.json
digest.json
```

## Next Gate

The workflow is available on the default branch through PR #545.

```text
workflow id: 274668919
first workflow_dispatch result: pass, run 25676030410
```

The first run is recorded in:

```text
globalpulse_public_web_smoke_workflow_run_results.md
```

For future runs, record:

```text
workflow run id
pages status
config status
health status
digest status
digest item_count
forbidden fragment check result
```

Suggested next PR:

```text
Record GlobalPulse public web smoke workflow run
```

## Guardrails

```text
Do not change frontend shell behavior in this PR.
Do not change backend runtime behavior in this PR.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not enable production scheduled polling.
Do not set new sources active=true.
```
