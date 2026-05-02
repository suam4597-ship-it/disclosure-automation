# Stage 5.6 manual live provider integration guardrails

This document defines guardrails for any future manual live provider integration after Stage 5.5 locked provider source health.

This is a documentation-only guardrail file. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base source: PR #108 Lock Stage 5.5 provider source health
locked official source: jp_tdnet_timely_disclosure
locked health state contract: Stage55ProviderHealthState
locked health evaluator: Stage55OfflineProviderHealthEvaluator
locked provider ingestion boundary: Stage54ProviderIngestionBoundary
locked offline staging: Stage54OfflineProviderRawStaging
locked overlay behavior: metadata-only, attach-only, non-canonical
```

## Mandatory manual-only guardrail

Manual provider integration must not run automatically.

Required:

```text
manual_trigger_required=true
use_live_fetch=false by default
scheduler_enabled=false
operator action required
no feed/API read side effects
no read model side effects
no materializer side effects
```

Forbidden:

```text
scheduler-triggered provider fetch
background provider polling loop
provider fetch on GET request
provider fetch during feed rendering
provider fetch during event detail rendering
provider fetch during materialization without explicit operator action
```

## Mandatory credential guardrail

Credentials must remain outside repository files.

Forbidden in code, tests, fixtures, docs, comments, logs, and persisted diagnostics:

```text
real provider keys
real provider tokens
real subscription keys
real authorization values
real cookie values
signed private URLs
raw request headers
raw response headers
```

Allowed only as redacted placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Mandatory request guardrail

Future live requests must be bounded and redaction-first.

Required:

```text
timeout_ms <= 5000
retry_count <= 1
no request header logging
no response header logging
no response body logging
no credential logging
no cookie logging
no signed URL logging
```

## Mandatory response guardrail

Provider responses must be converted to metadata-only output before any staging.

Allowed output:

```text
provider
source_key
article_external_id
canonical_event_id
title metadata
published_at metadata
public citation URL if allowed
language
jurisdiction
match evidence
redacted diagnostics
```

Forbidden output:

```text
raw response body
full article text
request headers
response headers
provider credentials
signed private URLs
unbounded provider error payloads
```

## Mandatory boundary guardrail

Future implementation must either reuse or prove equivalence to:

```text
Stage54ProviderIngestionBoundary
Stage54OfflineProviderRawStaging
Stage55ProviderHealthState
Stage55OfflineProviderHealthEvaluator
```

Required invariants:

```text
metadata_only=true
overlay_mode=attach_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
advisory_health_only=true
```

## Mandatory visibility guardrail

Provider overlay visibility requires direct official TDnet match evidence.

Required before visible overlay creation:

```text
canonical_event_id equals official TDnet event id
matched official stable external id is present when available
provider source is not paused
provider diagnostics pass redaction
provider health is not redaction_violation
provider health is not manual_review_required
```

If evidence is missing or ambiguous:

```text
state=manual_review_required
visible overlay creation disabled
no canonical mutation
```

## Mandatory canonical no-mutation guardrail

Manual provider integration must not write canonical facts.

Forbidden:

```text
mutating official TDnet headline/title
mutating official TDnet published_at
mutating official TDnet official_source_url
mutating official TDnet stable_external_id
creating provider canonical feed items
creating news-only canonical events
automatic canonical fact override
```

## Mandatory failure isolation guardrail

Provider failures must not affect TDnet or existing safe overlays.

Required:

```text
TDnet runtime remains independent
existing safe overlays remain available
provider failure records redacted health only
provider failure does not remove overlays
provider failure does not mutate canonical feed items
provider failure does not change feed/API response shapes
```

## Mandatory response-shape guardrail

Locked response shapes must remain unchanged:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

Do not change:

```text
feed item_count
feed item ordering
official TDnet fields
official citations
overlay citation separation
API response envelope
```

## Required implementation evidence

Any future Stage 5.6 implementation PR must prove:

```text
manual trigger only
live fetch default-off
scheduler disabled
credentials absent from repo
request/response logs redacted
metadata-only normalization
boundary validation preserved
raw staging idempotency preserved
health evaluator mapping preserved
canonical no-mutation
response shapes unchanged
failure isolation
redaction check
```

## Stop conditions

Do not merge if a future Stage 5.6 PR:

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
