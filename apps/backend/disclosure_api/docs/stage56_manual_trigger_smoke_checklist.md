# Stage 5.6 manual trigger smoke checklist

This checklist defines how a future operator-only manual provider invocation should be verified.

This is a documentation-only checklist. It does not add runtime trigger code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.6 PR D
scope: manual trigger smoke checklist
mode: docs-only
runtime trigger code: none
provider credentials: none
scheduler changes: none
live fetch code: none
routes/feed-controller changes: none
canonical mutation: none
```

## Manual trigger pre-flight

Future implementation must prove:

```text
manual_trigger=true is required
operator_reason is present
transport_mode defaults to fake
use_live_fetch defaults to false
scheduler_enabled defaults to false
timeout_ms is bounded
retry_count is bounded
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

## Invocation safety smoke

Verify future invocation cannot run from:

```text
public unauthenticated route
feed request
event detail request
read model call
materializer call
scheduler tick
background polling loop
```

Expected:

```text
operator-only invocation: PASS
no read side effects: PASS
no scheduler side effects: PASS
no feed/API side effects: PASS
```

## Fake transport smoke

For the first implementation, fake transport should remain the default.

Expected:

```text
fake transport accepted: PASS
real transport disabled by default: PASS
live transport opt-in rejected unless separately scoped: PASS
no real network call observed: PASS
```

## Boundary smoke

Future invocation must flow through locked contracts:

```text
Stage56ManualProviderAdapterContract validates manual request: PASS
Stage56RedactedProviderResultAdapter maps result: PASS
Stage54ProviderIngestionBoundary normalizes metadata-only payload: PASS
Stage55OfflineProviderHealthEvaluator evaluates diagnostics: PASS
```

## Redaction smoke

Search invocation inputs, logs, diagnostics, persisted rows, and comments.

Must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
raw response bodies
full article text
unbounded error payloads
```

Allowed only as redacted placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Failure smoke

Simulate or provide fake failure diagnostics and verify:

```text
provider timeout maps to timeout health: PASS
provider rate limit maps to rate_limited health: PASS
provider error maps to failed health: PASS
redaction violation maps to redaction_violation health: PASS
ambiguous match maps to manual_review_required health: PASS
TDnet runtime unaffected: PASS
feed/API serving unaffected: PASS
existing overlays remain available: PASS
canonical feed items unchanged: PASS
```

## Response-shape smoke

Before and after invocation, verify:

```text
read model item.overlays[] shape unchanged: PASS
API item.overlays[] shape unchanged: PASS
feed news_overlays[] shape unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
overlay citation separation unchanged: PASS
```

## Required regression set for future implementation

Future manual trigger implementation should run relevant new tests plus:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Changed-file guardrail for this docs PR

This PR may add only:

```text
apps/backend/disclosure_api/docs/stage56_manual_trigger_operator_invocation_design.md
apps/backend/disclosure_api/docs/stage56_manual_trigger_smoke_checklist.md
apps/backend/disclosure_api/docs/stage56_manual_trigger_credential_redaction_checklist.md
```

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema files
scheduler code
provider clients
live fetch code
routes
feed/controller code
materializer code
API behavior
feed behavior
canonical feed mutation behavior
```

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
operator invocation design added: PASS
manual trigger smoke checklist added: PASS
credential/redaction checklist added: PASS
manual-only invocation documented: PASS
fake transport default documented: PASS
live fetch default-off documented: PASS
scheduler disabled documented: PASS
redaction guardrail documented: PASS
response-shape guardrail documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/materializer/API/canonical code changes: PASS
```
