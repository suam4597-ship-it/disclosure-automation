# GlobalPulse EU Scheduled Staging Canary Manual Dispatch

This document records the manual-dispatch path for running the first EU scheduled staging canary before the next weekday cron.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, source activation, or production scheduled polling.

## Conclusion

```text
EU_CANARY_MANUAL_DISPATCH_PATH_RECORDED
EU_CANARY_SCHEDULED_CRON_PRESERVED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
EU_PUBLIC_UI_AND_API_SHAPE_UNCHANGED
```

## Baseline

```text
runbook doc: globalpulse_eu_scheduled_staging_canary_runbook.md
configuration doc: globalpulse_eu_scheduled_staging_canary_configuration_results.md
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
scheduled EU cron: 17 */4 * * 1-5
backend URL: https://globalpulse-backend-staging.fly.dev
source status: active=false
candidate status: manual_staging_only
```

## Manual Dispatch Contract

To run the first EU canary manually through the existing workflow:

```text
workflow: GlobalPulse live staging poll
event: workflow_dispatch
input backend_url: https://globalpulse-backend-staging.fly.dev
input source_key: eu_scheduled_staging_canary
input edition: breaking
```

Expected resolver behavior:

```text
REQUESTED_SOURCE_KEY=eu_scheduled_staging_canary
SOURCE_KEY=eu_scheduled_staging_canary
RUN_MODE=eu_canary
EU_CANARY_SOURCES populated from the first-canary source list
```

The special `eu_scheduled_staging_canary` source key is a workflow sentinel only. It is not a registry source and must not be added to `source_registry.sample.yaml`.

## Guardrails

```text
existing SEC scheduled routing remains unchanged
existing India NSE scheduled routing remains unchanged
EU scheduled cron remains unchanged
manual single-source workflow_dispatch remains supported
source active flags remain unchanged
production scheduled EU polling remains disabled
Germany Company Register remains excluded from the first canary
Prague/PSE remains excluded from the first canary
no public UI/API shape change
```

## Next Result To Record

After manually dispatching the workflow, record:

```text
workflow run URL
artifact name and id
health status
per-source poll status
per-source fetch.mode and fetch.status_code
per-source records_seen and records_inserted
digest status and fallback_to_fixture
source distribution in latest digest
any date-specific digest checks needed because latest top-N does not show a source
```

## Current Conclusion

```text
EU_CANARY_MANUAL_DISPATCH_READY
NEXT_STEP_RUN_WORKFLOW_DISPATCH_AND_RECORD_SMOKE
```
