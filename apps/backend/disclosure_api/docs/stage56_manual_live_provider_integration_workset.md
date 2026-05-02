# Stage 5.6 manual live provider integration workset

This document defines the recommended implementation sequence for manual live provider integration after Stage 5.5 locked provider source health.

This is a planning document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b8f9544cd9bb6edae5cdf3b8fea12e50fedb0f00
base source: PR #108 Lock Stage 5.5 provider source health
stage: Stage 5.6 manual live provider integration
status: design-only
locked provider health: advisory, redacted, non-canonical
locked provider ingestion: metadata-only, attach-only, default-off
locked live fetch state before implementation: out of scope
```

## Recommended PR sequence

Stage 5.6 should be split into small PRs:

```text
PR A: docs-only manual live provider integration design
PR B: manual provider adapter behavior + fake transport contract
PR C: redacted provider result adapter to Stage54ProviderIngestionBoundary
PR D: manual trigger smoke design or operator-only invocation design
PR E: docs-only lock close-out
```

Do not combine provider transport, credential handling, scheduler behavior, staging, materialization, and feed/API changes in one PR.

## PR A: design-only manual live provider integration plan

Recommended branch:

```text
chatgpt-stage56-manual-live-provider-integration-design-v1
```

Allowed scope:

```text
manual live provider integration design doc
manual live provider integration guardrails doc
manual live provider integration workset doc
```

Disallowed scope:

```text
runtime code
tests
fixtures
migrations
schema changes
provider clients
live HTTP fetches
scheduler changes
routes
feed/controller changes
materializer changes
canonical mutation
```

Verification:

```text
docs-only changed files
manual-only policy documented
default-off policy documented
credential sourcing policy documented
redaction policy documented
failure isolation documented
future implementation sequence documented
```

## PR B: manual provider adapter behavior + fake transport contract

Recommended branch:

```text
chatgpt-stage56-manual-provider-adapter-contract-v1
```

Allowed scope:

```text
provider adapter behavior module or contract
fake transport used only in tests
manual-only invocation validation
unit tests
manual smoke doc
```

Required behavior:

```text
no real network calls
no real credentials
manual trigger required
use_live_fetch=false by default
scheduler_enabled=false
bounded request options represented but not executed
request/response headers absent from persisted result
```

Disallowed scope:

```text
real provider HTTP client
real provider credentials
scheduler
migrations
schema changes
routes/feed-controller changes
materializer changes
canonical mutation
```

Required tests:

```text
fake transport accepted
real transport disabled by default
manual trigger required
scheduler opt-in rejected
credentials rejected
request headers rejected from persisted result
response body rejected from persisted result
```

## PR C: redacted provider result adapter

Recommended branch:

```text
chatgpt-stage56-redacted-provider-result-adapter-v1
```

Allowed scope:

```text
map fake/manual provider transport result into Stage54ProviderIngestionBoundary payload
metadata-only adapter tests
redaction tests
manual smoke doc
```

Required behavior:

```text
provider result normalizes to metadata-only payload
full article text is rejected
raw response body is rejected
request/response headers are rejected
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

Required regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

## PR D: manual trigger smoke design

Recommended branch:

```text
chatgpt-stage56-manual-trigger-smoke-design-v1
```

Allowed scope:

```text
docs-only operator invocation design
manual smoke checklist
credential sourcing checklist
redaction checklist
stop conditions
```

Disallowed scope:

```text
runtime trigger code
provider credentials
scheduler changes
live fetch code
routes/feed-controller changes
materializer changes
canonical mutation
```

## PR E: lock close-out

Recommended branch:

```text
chatgpt-stage56-manual-live-provider-integration-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
merge SHA references
PASS evidence
remaining out-of-scope list
```

## Required regression set for runtime PRs

Runtime PRs should run relevant new Stage 5.6 tests plus:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Docs-only PRs require docs-only guardrail verification only.

## Stop conditions

Do not merge if any Stage 5.6 PR:

```text
adds real credentials
turns live fetch on by default
adds scheduler-triggered provider fetch
logs request or response headers
logs response bodies
stores full article text
stores raw provider payload dumps
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
breaks Stage 5.5 health regressions
breaks Stage 5.4 offline staging idempotency
breaks redaction checks
```

## Future after Stage 5.6 lock

Possible future stages after manual live provider integration is locked:

```text
provider source health operator view
cross-source duplicate group materialization
attachment review/admin tooling
scheduler design for provider ingestion
provider-specific live integration PRs
```
