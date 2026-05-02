# Stage 5.4 provider ingestion guardrails

This document defines mandatory guardrails for future provider-backed ingestion work after Stage 5.3 multi-overlay behavior was locked.

This is a guardrail document only. It does not add runtime code, provider clients, live fetches, credentials, tests, fixtures, migrations, schedulers, routes, feed/controller changes, or canonical feed mutations.

## Locked baseline

```text
base commit: 03a2bc552777405e071a1d70fc944dae16108ee3
base source: PR #98 Close out Stage 5.3 multi-overlay lock
official canonical source: jp_tdnet_timely_disclosure
overlay model: attach_only
locked response shapes:
  - item.overlays[]
  - news_overlays[]
locked canonical rule: provider overlays do not create or mutate canonical feed items
```

## Mandatory source-of-truth guardrail

TDnet remains the only canonical source for the locked event path.

Provider-backed ingestion must preserve:

```text
canonical_feed_items official TDnet row count
official event id
official stable external id
official source URL
official headline/title
official published_at
official citations
```

Provider data must remain overlay context unless a later stage explicitly reopens canonical source policy.

## Mandatory attach-only guardrail

Provider-backed overlays must default to:

```text
overlay_mode=attach_only
canonical_fact_override=false
news_only_event_creation=false
canonical_feed_mutation=false
```

Any attempt to set `canonical_fact_override=true` must fail validation or remain hidden pending a separately designed review workflow.

## Mandatory direct-match guardrail

A provider-backed overlay may become visible only with direct official match evidence.

Required evidence examples:

```text
canonical_event_id equals official TDnet event id
matchedCanonicalEventId equals official TDnet event id
matchedOfficialStableExternalId equals official stable external id
provider article metadata references the official TDnet disclosure id
```

Absent or ambiguous evidence must not become visible.

Recommended hidden states:

```text
hidden_missing_direct_official_identifier
hidden_conflict_requires_review
hidden_source_not_allowed
hidden_provider_fetch_error
hidden_redaction_violation
```

## Mandatory credential guardrail

Repository files must not contain real provider credentials.

Forbidden in code, tests, fixtures, docs, logs, comments, and sample config:

```text
real Subscription-Key values
real Authorization header values
real Cookie header values
provider bearer tokens
provider usernames/passwords
signed private URLs
unredacted request headers
```

Allowed in docs/sample config only when clearly redacted:

```text
REDACTED_SUBSCRIPTION_KEY
REDACTED_AUTHORIZATION
REDACTED_COOKIE
REDACTED_REUTERS_API_KEY
REDACTED_BLOOMBERG_API_KEY
```

## Mandatory live-fetch guardrail

Live provider fetch must not be enabled by default.

Required defaults:

```text
use_live_fetch=false
scheduler disabled
manual trigger only for first live-fetch slice
bounded timeout
bounded retries
redacted logs only
no request headers in logs
no response body dumps in logs
```

The first Stage 5.4 implementation slice should prefer an offline provider adapter seam over real network integration.

## Mandatory storage guardrail

Provider-backed ingestion must be metadata-only by default.

Allowed storage:

```text
provider name
source key
article external id
title/headline metadata
published_at metadata
public citation URL if allowed
language
jurisdiction
overlay claims metadata
redacted diagnostics
```

Forbidden storage:

```text
full article body
raw provider payload dumps
request headers
credentials
cookies
bearer tokens
signed private URLs
unbounded provider error bodies
```

## Mandatory response-shape guardrail

Provider-backed ingestion must not change locked response shapes.

Required stable shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

Provider-backed ingestion must not change:

```text
feed item count
feed item ordering
official TDnet fields
official source URL
official citation semantics
top-level API response envelope
```

## Mandatory citation guardrail

Citation separation remains locked:

```text
official citations:
  isCanonicalSource=true
  sourceKey=jp_tdnet_timely_disclosure

overlay citations:
  isCanonicalSource=false
  sourceKey=<provider overlay source key>
```

Tests must verify non-canonical overlay citations are filterable by `isCanonicalSource=false`.

## Mandatory idempotency guardrail

Provider-backed staging and materialization must be idempotent.

Required behavior:

```text
same provider article produces same external_event_key
same provider article produces same overlay_id
same provider article materializes one attachment row per official event
re-run does not create duplicate canonical feed items
re-run does not create duplicate visible attachments
```

## Mandatory failure isolation guardrail

Provider failures must not affect official TDnet ingestion or feed serving.

Required behavior:

```text
TDnet runtime can pass while provider is unavailable
provider timeout does not remove existing overlays
provider error does not mutate official canonical item
provider error does not create canonical feed item
provider error diagnostics are redacted and bounded
```

## Mandatory test evidence for implementation PRs

Runtime implementation PRs must include or preserve tests for:

```text
idempotent provider staging
no canonical mutation
no provider canonical feed item creation
visible only with direct official match
hidden when match evidence is missing
redaction of credentials and request headers
stable read model/API/feed shapes
citation separation
regressions for Stage 5.3 multi-overlay behavior
```

## Required regression set for runtime PRs

Future runtime PRs should run at least:

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

Additional Stage 5.4 tests should be added per implementation slice.

## Merge stop conditions

Do not merge if a Stage 5.4 PR:

```text
introduces real credentials
introduces live fetch by default
adds scheduler-triggered provider fetch before manual-mode lock
stores full article text
logs request headers
logs response bodies
creates provider canonical feed items
creates news-only canonical events
mutates official TDnet canonical facts
changes locked API/feed shape unexpectedly
breaks Stage 5.3 multi-overlay ordering
breaks citation separation
breaks redaction checks
```
