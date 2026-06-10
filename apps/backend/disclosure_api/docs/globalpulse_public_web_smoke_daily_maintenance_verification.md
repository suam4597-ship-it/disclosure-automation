# GlobalPulse Public Web Smoke Daily Maintenance Verification

Date: 2026-05-11 KST

This document records the manual maintenance verification run after the public web smoke workflow was scheduled daily on `main` and opted JavaScript actions into Node.js 24.

This is smoke documentation. It does not change frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_MAIN_PASS
PUBLIC_PAGES_SHELL_CONTRACT_PASS
PUBLIC_PAGES_CONFIG_MARKER_PASS
FLY_STAGING_HEALTH_PASS
FLY_STAGING_DIGEST_PASS
FORBIDDEN_PUBLIC_FRAGMENT_CHECK_PASS
ARTIFACT_UPLOAD_PASS
NODE24_ACTION_RUNTIME_OPT_IN_PRESENT
NODE20_FORCED_RUNTIME_WARNING_STILL_PRESENT
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
```

## Workflow Run

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
workflow id: 274668919
run id: 25677329262
job id: 75378900931
event: workflow_dispatch
ref: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
created_at: 2026-05-11T14:45:32Z
completed_at: 2026-05-11T14:46:02Z
conclusion: success
url: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25677329262
```

## Inputs

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
backend_url: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

## Runtime Environment Marker

```text
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

The workflow accepted the Node.js 24 opt-in environment variable and completed successfully.

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
phase: phase1
repo: up
```

Backend digest:

```text
digest status: 200
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
forbidden public response fragments: none found
```

Observed live-region coverage in the digest sample:

```text
india
eu_north
ch
eu_central
greater_china
asean
eu
uk
eu_south
```

Artifact:

```text
artifact name: globalpulse-public-web-smoke-25677329262
artifact id: 6921549242
artifact files: pages.html, config.js, health.json, digest.json
artifact upload: success
```

## Warning

The workflow still emitted GitHub-hosted Actions JavaScript runtime warnings even though the Node.js 24 opt-in was present.

```text
Node.js 20 is deprecated.
The following actions target Node.js 20 but are being forced to run on Node.js 24:
actions/upload-artifact@v4.
```

It also emitted Node runtime deprecation warnings from the artifact upload path:

```text
DEP0040 punycode module is deprecated.
DEP0169 url.parse() behavior is not standardized.
```

These warnings did not fail the smoke run. Treat this as a maintenance note for the GitHub-hosted runner/action stack, not a GlobalPulse product failure.

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
