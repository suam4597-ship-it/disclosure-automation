# Stage 5.5 provider source health workset

This document defines the recommended implementation sequence for provider source health policy after Stage 5.4 locked the offline provider ingestion seam.

This is a planning document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 66fefb8132cc54d18afb017bfee8479312f105ef
base source: PR #103 Lock Stage 5.4 offline provider ingestion seam
stage: Stage 5.5 provider source health policy
status: design-only
locked official source: jp_tdnet_timely_disclosure
locked offline provider source: stage54_offline_provider_fixture
locked provider behavior: metadata-only, attach-only, non-canonical
locked live fetch state: out of scope and default-off
```

## Recommended PR sequence

Stage 5.5 should be split into small PRs:

```text
PR A: docs-only provider source health policy design
PR B: provider health state contract + pure validation tests
PR C: offline provider health evaluator using redacted diagnostics
PR D: optional source health read model docs or additive test-only projection design
PR E: docs-only lock close-out
```

Do not combine health state storage, scheduler behavior, live provider fetch, and feed/API behavior changes in one PR.

## PR A: provider source health policy design

Recommended branch:

```text
chatgpt-stage55-provider-source-health-policy-design-v1
```

Allowed scope:

```text
provider source health policy design doc
provider source health guardrails doc
provider source health workset doc
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
state model documented
redaction policy documented
failure isolation documented
future implementation sequence documented
```

## PR B: provider health state contract

Recommended branch:

```text
chatgpt-stage55-provider-health-state-contract-v1
```

Allowed scope:

```text
pure provider health state contract module
state allowlist validation
redacted diagnostic validation
unit tests
manual smoke doc
```

Required behavior:

```text
safe default state is unknown or paused
unknown state values are rejected or normalized to unknown
redaction violation is detectable without persisting secrets
request/response headers are rejected
full article text is rejected
provider credentials are rejected
no DB writes
no network calls
no scheduler
no routes/feed changes
```

Required tests:

```text
allowed states accepted
unknown unsafe states rejected or normalized
redacted diagnostic allowlist enforced
credentials rejected
request headers rejected
response body rejected
redaction_violation state produced for unsafe diagnostics
```

## PR C: offline provider health evaluator

Recommended branch:

```text
chatgpt-stage55-offline-provider-health-evaluator-v1
```

Allowed scope:

```text
offline evaluator over Stage 5.4 redacted diagnostics
test-only payloads in test code
unit tests
manual smoke doc
```

Required behavior:

```text
success diagnostics -> healthy
partial metadata -> degraded
rate limit diagnostics -> rate_limited
timeout diagnostics -> timeout
error diagnostics -> failed
redaction violation -> redaction_violation
ambiguous match -> manual_review_required
paused source -> paused
```

Disallowed scope:

```text
live fetch
provider credentials
scheduler
migrations
schema changes
routes/feed-controller changes
materializer changes
canonical mutation
```

Required regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## PR D: source health projection design

Recommended branch:

```text
chatgpt-stage55-source-health-projection-design-v1
```

Allowed scope:

```text
docs-only additive projection design
manual smoke checklist
response-shape guardrails
```

Disallowed scope:

```text
new routes
feed/controller changes
runtime projection code
migrations
schema changes
scheduler
live fetch
canonical mutation
```

The design must define whether source health is shown through:

```text
existing internal source health endpoints if available
operator-only diagnostics
future additive API contract
manual smoke logs only
```

## PR E: lock close-out

Recommended branch:

```text
chatgpt-stage55-provider-source-health-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
merge SHA references
PASS evidence
remaining out-of-scope list
```

## Required regression set for runtime PRs

Runtime PRs should run the relevant new Stage 5.5 tests plus:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Docs-only PRs require docs-only guardrail verification only.

## Stop conditions

Do not merge if any Stage 5.5 PR:

```text
adds live fetch by default
adds provider credentials
adds scheduler-triggered provider fetch
stores request or response headers
stores response bodies
stores full article text
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
deletes existing safe overlays on provider health failure
breaks Stage 5.4 offline staging idempotency
breaks Stage 5.3 multi-overlay ordering
breaks redaction checks
```

## Future after Stage 5.5 lock

Possible future stages after provider source health policy is locked:

```text
manual live provider integration with health updates
provider source health operator view
cross-source duplicate group materialization
attachment review/admin tooling
scheduler design for provider ingestion
```
