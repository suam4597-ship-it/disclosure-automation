# GlobalPulse Public Web Smoke Daily Schedule

Date: 2026-05-11 KST

This document records the daily schedule added to the public web smoke workflow after the first manual dispatch run passed.

This change does not alter frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_DAILY_SCHEDULE_ADDED
PUBLIC_WEB_SMOKE_WORKFLOW_DISPATCH_RETAINED
DAILY_READONLY_PAGES_AND_BACKEND_SMOKE_ADDED
NODE24_ACTION_RUNTIME_OPT_IN_ADDED
PRODUCTION_DEPLOYMENT_NOT_CHANGED
```

## Schedule

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
cron: 17 0 * * *
frequency: daily
default pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
default backend_url: https://globalpulse-backend-staging.fly.dev
default edition: breaking
```

The schedule runs against staging-backed public Pages. It is not a production launch signal.

## Node.js Runtime Maintenance

The first successful manual smoke run emitted GitHub's Node.js 20 deprecation warning for JavaScript actions.

The workflow now sets:

```text
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true
```

This is intended to keep `actions/upload-artifact@v4` aligned with the upcoming hosted runner default.

## Guardrails

```text
Do not treat the daily public web smoke as production monitoring.
Do not point public Pages at a production backend in this PR.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
```

## Next Gate

After this schedule is active on `main`, run one manual dispatch to verify the Node.js 24 opt-in does not break artifact upload, then record the result if needed.

Status:

```text
manual maintenance verification after main activation: pass
run id: 25677329262
result doc: globalpulse_public_web_smoke_daily_maintenance_verification.md
artifact upload: pass
Node.js 24 opt-in: present
Node.js 20 forced-runtime warning: still present, non-blocking
```
