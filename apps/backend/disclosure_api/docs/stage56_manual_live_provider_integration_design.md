# Stage 5.6 manual live provider integration design

This document defines a docs-only design for a future manual live provider integration after Stage 5.5 locked provider source health as an advisory, redacted, non-canonical policy layer.

This is a design document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b8f9544cd9bb6edae5cdf3b8fea12e50fedb0f00
base source: PR #108 Lock Stage 5.5 provider source health
stage: Stage 5.6 manual live provider integration design
status: docs-only
locked official source: jp_tdnet_timely_disclosure
locked provider health contract: Stage55ProviderHealthState
locked provider health evaluator: Stage55OfflineProviderHealthEvaluator
locked offline ingestion boundary: Stage54ProviderIngestionBoundary
locked offline staging: Stage54OfflineProviderRawStaging
locked live fetch state before Stage 5.6 implementation: out of scope and default-off
```

## Goal

Stage 5.6 should define how a future provider integration can be manually invoked while preserving the Stage 5.4 and Stage 5.5 locks.

The first implementation after this design must remain:

```text
manual-only
default-off
redaction-first
metadata-only
attach-only
non-canonical
failure-isolated
```

## Non-goals

This PR does not authorize:

```text
live provider fetch code
provider clients
provider credentials in repository files
scheduler-triggered provider fetch
runtime config code changes
migrations
schema changes
routes
feed/controller changes
materializer changes
API response changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Manual integration principle

Manual live provider integration must be an explicit operator action, not a side effect of serving reads.

Required principle:

```text
operator action -> bounded provider request -> redacted metadata result -> Stage54ProviderIngestionBoundary -> offline-compatible raw staging -> advisory health update
```

Disallowed path:

```text
feed/API read -> live provider request
scheduler tick -> provider request
materializer call -> provider request
read model call -> provider request
```

## Credential sourcing policy

Future implementation must source credentials only from runtime environment or a secret manager-backed runtime configuration.

Repository files may include redacted placeholders only:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

Repository files must not include real values for:

```text
provider keys
provider tokens
subscription keys
cookie values
authorization values
signed private URLs
```

## Provider request policy

Future manual provider requests must be bounded and non-retrying by default.

Recommended defaults:

```text
manual_trigger_required=true
use_live_fetch=false by default
provider_live_fetch_enabled=false by default
scheduler_enabled=false
timeout_ms <= 5000
retry_count <= 1
store_full_text=false
log_request_headers=false
log_response_headers=false
log_response_body=false
redact_errors=true
```

## Provider response policy

Provider responses must be normalized into a metadata-only candidate before staging.

Allowed normalized metadata:

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
redacted diagnostics
match evidence
```

Forbidden normalized or persisted data:

```text
request headers
response headers
provider credentials
signed private URLs
raw response bodies
full article body text
unbounded error payloads
```

## Boundary and staging policy

Manual provider integration must reuse or preserve the Stage 5.4 boundary and staging contracts:

```text
Stage54ProviderIngestionBoundary validates metadata-only payloads
Stage54OfflineProviderRawStaging-compatible behavior stages raw document and raw event
same provider article remains idempotent
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
overlay_mode=attach_only
```

If future implementation needs a provider-specific staging adapter, it must prove equivalence to the locked offline staging behavior.

## Health policy

Manual provider integration must update provider health only through redacted, advisory diagnostics.

Future implementation should map diagnostics through Stage 5.5 rules:

```text
success -> healthy
partial metadata -> degraded
rate limit -> rate_limited
timeout -> timeout
provider error -> failed
redaction violation -> redaction_violation
ambiguous or missing match -> manual_review_required
paused provider -> paused
```

Provider health remains advisory and must not mutate canonical data.

## Visibility policy

Provider metadata may become visible only when all of the following are true:

```text
provider payload passed redaction boundary
provider payload is metadata-only
direct official TDnet match evidence exists
provider source is not paused
provider health is not redaction_violation
canonical_feed_mutation=false
canonical_fact_override=false
```

Missing or ambiguous match evidence must become `manual_review_required` or remain hidden.

## Failure isolation policy

Provider failure must not affect official TDnet ingestion or serving.

Required behavior:

```text
TDnet runtime remains independent
provider timeout does not remove existing overlays
provider error does not mutate official canonical item
provider error does not create canonical feed item
provider health records only redacted diagnostics
feed/API serving continues from existing data
```

## Response-shape policy

Manual provider integration must not change locked response shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

It must not change:

```text
feed item_count
feed item ordering
official TDnet fields
official TDnet citations
overlay citation separation
top-level API envelopes
```

## Recommended first implementation slice

The first implementation after this design should be narrow:

```text
manual-only provider adapter behavior
redacted provider result mapper
test-only fake provider transport
no real credentials
no network by default
no scheduler
no routes
no feed/controller changes
no materializer changes
no schema changes
```

## Stop conditions

Do not merge a future manual provider integration PR if it:

```text
adds credentials to repository files
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
breaks Stage 5.5 provider health regressions
breaks Stage 5.4 offline staging idempotency
breaks redaction checks
```
