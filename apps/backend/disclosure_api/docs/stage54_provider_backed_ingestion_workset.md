# Stage 5.4 provider-backed ingestion workset

This document defines the recommended implementation sequence for Stage 5.4 provider-backed ingestion after Stage 5.3 multi-overlay lock.

This is a planning document only. It does not add provider clients, live fetches, credentials, runtime code, tests, fixtures, migrations, schedulers, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 03a2bc552777405e071a1d70fc944dae16108ee3
base source: PR #98 Close out Stage 5.3 multi-overlay lock
stage: Stage 5.4 provider-backed ingestion
status: design-only
locked official source: jp_tdnet_timely_disclosure
locked overlay sources:
  - stage5_news_overlay_fixture
  - stage53_news_overlay_fixture
locked overlay behavior: attach-only, no canonical mutation
```

## Design decision

Stage 5.4 should introduce provider-backed ingestion through small, reversible PRs. The first implementation should create an offline provider-ingestion seam, not a live provider integration.

Recommended principle:

```text
design first
offline seam second
manual live-fetch design third
manual live-fetch implementation only after offline seam is locked
scheduler only after manual live-fetch behavior is locked
```

## Recommended PR sequence

Stage 5.4 should be split into small PRs:

```text
PR A: docs-only provider-backed ingestion design
PR B: offline provider ingestion boundary + redacted result contract
PR C: offline provider staging test adapter
PR D: manual live-fetch design and smoke checklist
PR E: docs-only lock close-out for the offline ingestion seam
```

Do not combine live network fetch, scheduler integration, and read-model/feed behavior changes in one PR.

## PR A: design-only provider-backed ingestion plan

Recommended branch:

```text
chatgpt-stage54-provider-backed-ingestion-design-v1
```

Allowed scope:

```text
provider-backed ingestion design doc
provider ingestion guardrail doc
runtime workset doc
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
credentials
scheduler changes
routes
feed/controller changes
canonical mutation
```

Verification:

```text
docs-only changed files
provider-backed ingestion boundaries documented
credential/redaction guardrails documented
canonical no-mutation guardrails documented
implementation sequence documented
```

## PR B: offline provider ingestion boundary

Recommended branch:

```text
chatgpt-stage54-provider-ingestion-boundary-v1
```

Allowed scope:

```text
provider ingestion behavior module or plain data contract
redacted provider fetch result shape
offline adapter behaviour/protocol if needed
unit tests for redaction and defaults
manual smoke doc
```

Required behavior:

```text
no network calls
no scheduler
no credentials
use_live_fetch=false by default
provider result structs/maps contain only metadata and redacted diagnostics
full article text rejected or dropped
request headers rejected or dropped
```

Disallowed scope:

```text
live Reuters fetch
live Bloomberg fetch
real credentials
fixture payload changes unless test-only and redacted
migrations
schema changes
routes
feed/controller changes
canonical feed mutation
```

Required tests:

```text
redacted provider result accepts metadata-only payload
redacted provider result rejects or strips request headers
redacted provider result rejects or strips full article body
use_live_fetch default remains false
no canonical mutation helpers are introduced
```

## PR C: offline provider staging test adapter

Recommended branch:

```text
chatgpt-stage54-offline-provider-staging-v1
```

Allowed scope:

```text
offline provider adapter used only in tests
raw staging from offline provider result
idempotency tests
manual smoke doc
```

Required behavior:

```text
stage provider metadata into raw_events or existing staging path
stable external_event_key
stable overlay_id
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
visible only with direct official match evidence
hidden without direct official match evidence
no provider canonical feed item creation
```

Required regression set:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## PR D: manual live-fetch design

Recommended branch:

```text
chatgpt-stage54-manual-live-fetch-design-v1
```

Allowed scope:

```text
docs-only live-fetch design
manual smoke checklist
credential sourcing plan
redaction checklist
stop conditions
```

Disallowed scope:

```text
live fetch code
provider credentials
scheduler changes
runtime code
tests
migrations
routes
feed/controller changes
```

The live-fetch design must define:

```text
runtime config keys and redacted samples
manual trigger only
bounded timeout and retry policy
error redaction policy
no request/response body logging
provider rate-limit behavior
provider failure isolation from TDnet
```

## PR E: offline seam lock close-out

Recommended branch:

```text
chatgpt-stage54-offline-provider-ingestion-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
merge SHA references
PASS evidence
remaining out-of-scope list
```

## Required regression set for runtime implementation PRs

Runtime PRs should run the relevant new Stage 5.4 tests plus:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_staging_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_fixture_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Docs-only PRs require docs-only guardrail verification only.

## Manual smoke requirements for future runtime PRs

Manual smoke after a Stage 5.4 implementation PR should verify:

```text
official TDnet item exists
provider ingestion defaults to offline/manual mode
provider result contains no credentials or request headers
provider result contains no full article text
raw staging is idempotent
materialization remains idempotent
provider overlay does not create canonical feed item
provider overlay does not mutate official TDnet fields
read model/API/feed shapes remain unchanged
citation separation remains intact
redaction check passes
```

## Stop conditions

Do not merge if any Stage 5.4 PR:

```text
adds real provider credentials
adds live fetch by default
adds scheduler-triggered provider fetch before manual live-fetch lock
stores full provider article text
logs provider request headers
logs provider response bodies
creates provider canonical feed items
creates news-only canonical events
mutates official TDnet canonical fields
changes locked API/feed response shapes unexpectedly
breaks Stage 5.3 multi-overlay ordering
breaks citation separation
breaks redaction checks
```

## Future after Stage 5.4 offline seam lock

Possible future stages after the offline ingestion seam is locked:

```text
manual live Reuters provider integration
manual live Bloomberg provider integration
provider source health policy
cross-source duplicate group materialization
attachment review/admin tooling
scheduler integration for provider ingestion
```
