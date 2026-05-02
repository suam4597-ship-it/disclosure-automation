# Stage 5.5 source health projection smoke checklist

This checklist defines how a future source health projection implementation should be manually verified.

This is a documentation-only checklist. It does not add runtime projection code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.5 PR D
scope: source health projection smoke checklist
mode: docs-only
new routes: none
runtime projection code: none
feed/controller changes: none
live fetch: none
scheduler: none
canonical mutation: none
```

## Pre-flight checks

Before any future projection implementation is tested, verify:

```text
source health projection is read-only
source health projection is operator-only or test-only
projection call does not trigger provider live fetch
projection call does not trigger scheduler work
projection call does not mutate canonical feed items
projection call does not change feed/API response shapes
```

## Expected projection fields

Future implementation should expose only bounded, redacted fields such as:

```text
source_key
provider
health_status
advisory_only
last_checked_at
last_success_at
last_failure_at
retry_count
timeout
error_class
redaction_status
manual_review_reason
has_visible_overlays
has_recent_safe_overlay
```

## Forbidden projection fields

Projection output must not include:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
raw provider response bodies
full article text
unbounded provider error payloads
```

## Read-only smoke

Verify future implementation does not write to:

```text
canonical_feed_items
raw_documents
raw_events
news_overlay_attachments
source_registry health fields unless explicitly scoped in a separate implementation
source_cursors
```

Expected:

```text
projection is read-only: PASS
no canonical mutation: PASS
no overlay deletion: PASS
no provider canonical item creation: PASS
no news-only canonical event creation: PASS
```

## Response-shape smoke

Run existing feed/API checks before and after projection call.

Expected unchanged shapes:

```text
read model item.overlays[] shape unchanged: PASS
API item.overlays[] shape unchanged: PASS
feed news_overlays[] shape unchanged: PASS
feed item_count unchanged: PASS
feed item ordering unchanged: PASS
official TDnet fields unchanged: PASS
citation separation unchanged: PASS
```

## Redaction smoke

Search changed files, logs, test output, projected payloads, and persisted diagnostics.

Must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
full article text
raw provider response bodies
```

## Failure smoke

Simulate or provide failure diagnostics and verify:

```text
failed provider health projects as failed: PASS
timeout provider health projects as timeout: PASS
rate-limited provider health projects as rate_limited: PASS
redaction violation projects as redaction_violation: PASS
manual review required projects as manual_review_required: PASS
projection failure returns redacted error only: PASS
TDnet runtime unaffected: PASS
feed/API serving unaffected: PASS
```

## Required regression set for future implementation

Future source health projection implementation should run relevant new tests plus:

```powershell
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
apps/backend/disclosure_api/docs/stage55_source_health_projection_design.md
apps/backend/disclosure_api/docs/stage55_source_health_projection_smoke_checklist.md
apps/backend/disclosure_api/docs/stage55_source_health_projection_response_guardrails.md
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
projection design added: PASS
smoke checklist added: PASS
response-shape guardrails added: PASS
no runtime changes: PASS
no test changes: PASS
no fixture changes: PASS
no migrations/schema changes: PASS
no scheduler/provider/live-fetch code changes: PASS
no routes/feed-controller endpoint changes: PASS
no materializer/API/feed behavior changes: PASS
no canonical mutation behavior changes: PASS
redaction check: PASS
```
