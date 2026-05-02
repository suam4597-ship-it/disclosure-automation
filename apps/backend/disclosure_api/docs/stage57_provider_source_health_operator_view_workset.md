# Stage 5.7 provider source health operator view workset

This document defines the recommended implementation sequence for a provider source health operator view after Stage 5.6 locked the manual provider integration seam.

This is a planning document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, UI behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c8d435a639053a7ebb430c5779a4515ec2231bee
base source: PR #113 Lock Stage 5.6 manual live provider integration
stage: Stage 5.7 provider source health operator view
status: design-only
locked provider health: advisory, redacted, non-canonical
locked manual provider integration: operator-only, fake/default-off, metadata-only
locked public response shapes: item.overlays[] and news_overlays[]
```

## Recommended PR sequence

Stage 5.7 should be split into small PRs:

```text
PR A: docs-only operator view design
PR B: pure operator view projection contract + unit tests
PR C: internal read-only source health projection using existing Sources functions
PR D: operator authorization and audit design or test-only authorization guard
PR E: docs-only lock close-out
```

Do not combine public routes, source health actions, live provider fetch, scheduler behavior, and UI changes in one PR.

## PR A: docs-only operator view design

Recommended branch:

```text
chatgpt-stage57-provider-source-health-operator-view-design-v1
```

Allowed scope:

```text
operator view design doc
operator view authorization/response guardrails doc
operator view workset doc
```

Disallowed scope:

```text
runtime code
tests
fixtures
migrations
schema changes
routes
feed/controller changes
UI code
provider clients
live fetch
scheduler changes
materializer changes
canonical mutation
```

Verification:

```text
docs-only changed files
operator-only design documented
read-only design documented
response-shape guardrails documented
redaction policy documented
future implementation sequence documented
```

## PR B: pure operator view projection contract

Recommended branch:

```text
chatgpt-stage57-operator-view-projection-contract-v1
```

Allowed scope:

```text
pure projection contract module
redacted field allowlist
unit tests
manual smoke doc
```

Required behavior:

```text
operator projection accepts only bounded redacted source health fields
forbidden fields are rejected or dropped
view output is advisory-only
view output has no side-effect markers
no DB writes
no network calls
no scheduler
no routes/feed changes
```

Required tests:

```text
allowed projection fields accepted
credentials rejected
request headers rejected
response headers rejected
full article text rejected
raw provider response body rejected
read-only defaults preserved
public response shape fields not modified
```

## PR C: internal read-only source health projection

Recommended branch:

```text
chatgpt-stage57-internal-source-health-projection-v1
```

Allowed scope:

```text
internal read-only projection over Sources.list_source_health/1 and get_source_health/1
unit tests
manual smoke doc
```

Required behavior:

```text
read-only projection
operator/internal shape only
redacted output
no source health mutation
no enqueue_source_health_recheck call
no recompute_source_health call
no live provider fetch
no scheduler
no feed/API shape changes
no canonical mutation
```

Required regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage57_internal_source_health_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

## PR D: operator authorization and audit design

Recommended branch:

```text
chatgpt-stage57-operator-view-auth-audit-design-v1
```

Allowed scope:

```text
docs-only authorization design
operator permission checklist
audit checklist
manual smoke doc
```

Disallowed scope:

```text
runtime auth code
new routes
UI code
action endpoints
scheduler
live fetch
canonical mutation
```

Future runtime authorization work should be a separate implementation PR.

## PR E: lock close-out

Recommended branch:

```text
chatgpt-stage57-provider-source-health-operator-view-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
merge SHA references
PASS evidence
remaining out-of-scope list
```

## Required regression set for runtime PRs

Runtime PRs should run relevant new Stage 5.7 tests plus:

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

Docs-only PRs require docs-only guardrail verification only.

## Stop conditions

Do not merge if any Stage 5.7 PR:

```text
adds public or unauthenticated access
adds source health fields to public feed/API responses
triggers live provider fetch
triggers scheduler work
mutates source health in read-only view
mutates canonical feed items
creates provider canonical feed items
creates news-only canonical events
stores or exposes credentials
stores or exposes request or response headers
stores or exposes full article text
breaks locked response shapes
breaks redaction checks
```

## Future after Stage 5.7 lock

Possible future stages after provider source health operator view is locked:

```text
operator actions for source health with audit trail
cross-source duplicate group materialization
attachment review/admin tooling
scheduler design for provider ingestion
provider-specific live integration PRs
```
