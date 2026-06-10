# GlobalPulse Frontend Config Version Marker

Date: 2026-05-11 KST

This document records the first bounded runtime config marker added to the GlobalPulse static frontend.

This change does not promote production, change the backend API base, change routes, change public API response shapes, enable production polling, or promote source candidates.

## Conclusion

```text
GLOBALPULSE_FRONTEND_CONFIG_VERSION_MARKER_ADDED
RUNTIME_CONFIG_ENVIRONMENT_STAGING
RUNTIME_CONFIG_VERSION_STAGING_20260511_1
DISCLOSURE_API_BASE_COMPATIBILITY_RETAINED
PUBLIC_WEB_SMOKE_CONFIG_MARKER_CHECK_ADDED
PRODUCTION_BACKEND_NOT_CONFIGURED
```

## Runtime Marker

`apps/web/config.js` now exposes:

```text
window.GLOBALPULSE_RUNTIME_CONFIG.environment = staging
window.GLOBALPULSE_RUNTIME_CONFIG.apiBaseUrl = https://globalpulse-backend-staging.fly.dev
window.GLOBALPULSE_RUNTIME_CONFIG.configVersion = staging-20260511-1
window.GLOBALPULSE_RUNTIME_CONFIG.allowQueryParamOverride = true
```

Compatibility remains:

```text
window.DISCLOSURE_API_BASE_URL
```

The public shell still reads the compatibility field, so this is a bounded marker addition rather than a frontend rewrite.

## Smoke Contract

The public web smoke workflow now checks deployed `config.js` for:

```text
window.GLOBALPULSE_RUNTIME_CONFIG
environment: "staging"
configVersion: "staging-20260511-1"
allowQueryParamOverride: true
window.DISCLOSURE_API_BASE_URL
https://globalpulse-backend-staging.fly.dev
```

## Next Gate

After this reaches GitHub Pages and the workflow is available on `main`, run:

```text
GlobalPulse public web smoke
```

Record:

```text
workflow run id
config marker pass
health pass
digest pass
forbidden fragment check pass
```

## Guardrails

```text
Do not treat this as production config promotion.
Do not point public Pages at a production backend in this PR.
Do not disable staging query-param smoke override in this PR.
Do not change backend digest JSON response shape.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
```
