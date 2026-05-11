# GlobalPulse Public Web Smoke Workflow Run Results

Date: 2026-05-11 KST

This document records the first successful `GlobalPulse public web smoke` workflow run after the workflow was activated on `main` and updated to check the staging runtime config marker.

This is smoke documentation. It does not change frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_PASS
PUBLIC_PAGES_SHELL_CONTRACT_PASS
PUBLIC_PAGES_CONFIG_MARKER_PASS
FLY_STAGING_HEALTH_PASS
FLY_STAGING_DIGEST_PASS
FORBIDDEN_PUBLIC_FRAGMENT_CHECK_PASS
ARTIFACT_UPLOAD_PASS
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
```

## Workflow Run

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
workflow id: 274668919
run id: 25676030410
job id: 75374034259
event: workflow_dispatch
ref: main
head sha: 20c2cf42585afb71e55e9954cbc51b8cc8f0b1dc
created_at: 2026-05-11T14:22:12Z
conclusion: success
url: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25676030410
```

## Inputs

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
backend_url: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

## Step Results

```text
Show target: success
Fetch public Pages shell: success
Fetch public Pages config: success
Fetch backend health: success
Fetch backend digest: success
Upload smoke outputs: success
```

Public Pages shell:

```text
pages status: 200
public shell contract: pass
required markers: GlobalPulse, config.js, Source Health, apiBase
```

Public Pages config:

```text
config status: 200
public config contract: pass
required marker: window.GLOBALPULSE_RUNTIME_CONFIG
required marker: environment: staging
required marker: configVersion: staging-20260511-1
required marker: allowQueryParamOverride: true
required marker: window.DISCLOSURE_API_BASE_URL
required marker: https://globalpulse-backend-staging.fly.dev
required regional markers: greater_china, eu_north, eu_central, eu_south
```

Backend health:

```text
health status: 200
status: ok
service: disclosure_automation
```

Backend digest:

```text
digest status: 200
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
forbidden public response fragments: none found
```

Artifact:

```text
artifact name: globalpulse-public-web-smoke-25676030410
artifact id: 6920969918
artifact files: pages.html, config.js, health.json, digest.json
artifact upload: success
```

## Warning

The run emitted the GitHub-hosted Actions deprecation warning for `actions/upload-artifact@v4` using Node.js 20.

```text
Node.js 20 actions are deprecated.
```

This did not fail the smoke run. A follow-up workflow maintenance PR can opt into Node.js 24 or update the action/runtime behavior when appropriate.

## Guardrails

```text
This run validated staging-backed public Pages.
Production backend URL is not configured.
Production frontend config is not promoted.
Production scheduled polling is not enabled.
Candidate sources are not promoted active=true.
Backend digest JSON response shape is unchanged.
Public poll UI is not added.
Audit UI is not added.
Public Source Health UI is not added.
```
