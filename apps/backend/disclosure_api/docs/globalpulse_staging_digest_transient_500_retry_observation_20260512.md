# GlobalPulse Staging Digest Transient 500 Retry Observation

Date: 2026-05-12 KST

This document records a bounded transient observation for the Fly staging digest endpoint.

This is documentation-only. It does not change backend runtime behavior, frontend runtime behavior, routes, public API response shapes, workflow schedules, source activation, production polling, public poll UI, audit UI, public Source Health UI, dashboards, alerts, secrets, or hosting configuration.

## Conclusion

```text
GLOBALPULSE_STAGING_DIGEST_TRANSIENT_500_OBSERVED
GLOBALPULSE_STAGING_HEALTH_REMAINED_200_OK
GLOBALPULSE_STAGING_DIGEST_RETRY_RECOVERED_200
GLOBALPULSE_STAGING_DIGEST_FALLBACK_FALSE_AFTER_RETRY
NO_PERSISTENT_STAGING_DIGEST_OUTAGE_CLAIMED
NO_SOURCE_FAILURE_CLAIMED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observation

During a wait-time public digest check, the first request returned a server error:

```text
endpoint: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
result: 500 Internal Server Error
client: Windows PowerShell Invoke-RestMethod
```

The health endpoint remained healthy immediately afterward:

```text
endpoint: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
payload.status: ok
payload.service: disclosure_automation
payload.phase: phase1
payload.repo: up
```

The digest endpoint recovered on retry:

```text
endpoint: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
retry status: 200
digest_date: 2026-05-12
generated_at: 2026-05-12T03:33:41Z
edition: breaking
item_count: 10
metadata.fallback_to_fixture: false
first observed source: india_nse_announcements
```

A second retry after a short wait also returned:

```text
retry status: 200
digest_date: 2026-05-12
item_count: 10
metadata.fallback_to_fixture: false
first observed source: india_nse_announcements
```

## Interpretation

This is recorded as a transient retry-recovered staging observation, not as a persistent outage:

```text
health stayed 200 ok
digest recovered to 200 on retry
fallback_to_fixture stayed false after recovery
digest response shape remained usable after recovery
no source-specific failure is claimed
no workflow schedule change is implied
```

If repeated 500 responses appear in later checks, inspect Fly staging logs, recent backend deploys, database connectivity, digest query behavior, and latest source poll artifacts before changing runtime code.

## Follow-up

Next safe actions:

```text
continue public digest smoke checks
record repeat failures only if they recur
keep one-off transient evidence separate from scheduled source-poll observations
keep production approval blockers open until operator values are provided
do not promote production config from this observation
```

## Guardrails

```text
Do not change backend digest JSON response shape.
Do not add retry logic from this docs-only observation.
Do not change workflow schedules.
Do not set new sources active=true.
Do not enable production scheduled polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live success.
Do not infer source failure from a transient digest read failure.
JP live polling remains blocked by issue #339.
KR remains deferred until the dedicated backend/source path exists.
```
