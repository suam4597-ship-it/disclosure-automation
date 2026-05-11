# GlobalPulse Basic Monitoring And Incident Plan

Date: 2026-05-11 KST

This document defines the first monitoring and incident-response contract for the GlobalPulse public web and Fly backend workflow.

This is planning-only. It does not add dashboards, alerts, workflow schedules, runtime code, routes, controllers, migrations, frontend changes, backend response-shape changes, source activation, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_BASIC_MONITORING_PLAN_RECORDED
PUBLIC_WEB_SMOKE_IS_STAGING_OBSERVATION_NOT_PRODUCTION_MONITORING
HEALTH_AND_DIGEST_FRESHNESS_CHECKS_DEFINED
SOURCE_POLL_FAILURE_REVIEW_DEFINED
INCIDENT_RESPONSE_BOUNDARY_DEFINED
NO_ALERTING_OR_DASHBOARD_RUNTIME_ADDED
PRODUCTION_MONITORING_NOT_ENABLED
```

## Current Signals

Already available:

```text
public web smoke workflow: GlobalPulse public web smoke
public web smoke schedule: 17 0 * * *
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
Fly staging backend: https://globalpulse-backend-staging.fly.dev
live staging poll workflow: GlobalPulse live staging poll
source-health internal operator surfaces: protected internal UI/API only
```

The public web smoke is currently a staging-backed signal. It should not be labeled production monitoring until the production backend/frontend decisions are approved and deployed.

## Monitoring Layers

### 1. Public Web Availability

Check:

```text
GET public Pages URL: 2xx
HTML contains GlobalPulse shell markers
config.js is reachable
configVersion matches expected environment marker
```

Current implementation:

```text
GlobalPulse public web smoke workflow
```

First response if failing:

```text
check GitHub Pages deploy status
check latest phase0-foundation and main workflow sync
check config.js marker drift
do not change backend response shape to fix a frontend deploy issue
```

### 2. Backend Health

Check:

```text
GET /api/health: 200
status: ok
service: disclosure_automation
```

Current implementation:

```text
GlobalPulse public web smoke workflow
direct Fly staging curl/manual smoke
```

First response if failing:

```text
check Fly app status
check recent deploy/migration state
check DATABASE_URL/SECRET_KEY_BASE/PHX_HOST availability without printing secrets
check release logs for bounded failure messages
```

### 3. Digest Availability And Freshness

Check:

```text
GET /api/feed/digest/latest?edition=breaking: 200
edition: breaking
items: list
metadata.fallback_to_fixture: false for live staging smoke
forbidden public fragments: absent
```

Recommended freshness fields to watch:

```text
digest_date
generated_at
item_count
top source mix
region mix
metadata.fallback_to_fixture
```

First response if stale or empty:

```text
check whether the issue is source-specific or digest-wide
check latest live staging poll workflow runs
check source-health for recently failing sources
do not run production scheduled polling to make staging look healthy
```

### 4. Source Poll Workflow Health

Check:

```text
GlobalPulse live staging poll scheduled runs
source_key
run_mode
fetch.mode
records_seen
records_inserted
metadata.fallback_to_fixture
```

Current high-priority observations:

```text
SEC baseline
India NSE
EU canary
Denmark DFSA OAM
HKEX scheduled staging pending
```

First response if failing:

```text
classify source/network/parser/rate-limit failure
preserve existing source active flags
do not broaden source schedule in the same fix
record whether digest remains healthy through other regions
```

### 5. Public Response Safety

Check public responses for absence of:

```text
authorization
cookie
set-cookie
secret
token
session_id
raw_provider
raw_auth
raw_request
```

First response if found:

```text
stop production promotion
record the affected endpoint
patch the response boundary
add a regression test before resuming smoke documentation
```

## Incident Severity

Use this lightweight staging severity model until production monitoring is explicitly approved.

```text
S0: public response exposes secret/raw auth/session/provider/request material
S1: public Pages unavailable or backend health unavailable for staging smoke
S2: digest unavailable, stale, empty, or fixture fallback appears in live staging smoke
S3: one candidate source fails while other digest regions remain healthy
S4: scheduled workflow delay or skipped run with no product-facing impact
```

Suggested first action:

```text
S0: stop and patch boundary before any other work
S1: restore page/backend availability or roll back latest deploy/config
S2: inspect source-health and recent poll runs
S3: record source-specific observation and keep source inactive if candidate
S4: document pending status and wait for next window
```

## What To Record In An Incident Note

```text
timestamp
environment
frontend URL
backend URL
workflow run id
source key if applicable
observed status
expected status
first failing step
raw material exposure check result
rollback or wait decision
next review time
```

Do not include:

```text
secret values
raw cookies
authorization headers
session IDs
full provider payloads if they contain private/raw material
```

## Production Monitoring Gate

Before calling this production monitoring, decide:

```text
production frontend URL
production backend URL
production CORS origins
production uptime target
alert destination/owner
runbook owner
incident contact path
whether digest empty state is allowed at launch
source schedule policy
```

Until then:

```text
daily public web smoke remains staging observation
live staging poll workflows remain candidate-source observation
production scheduled polling remains disabled
```

## Guardrails

```text
Do not add alerting noise without an owner.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not print secrets or raw auth/session/request/provider material.
Do not claim latest-window feeds are complete market coverage.
Do not start JP live polling before source authority is resolved.
```

## Next Gate

The next safe monitoring implementation step is:

```text
record the first daily scheduled public web smoke run when it appears
record HKEX first automated scheduled staging run when it appears
only then consider production-specific monitoring targets after production deployment decisions are approved
```
