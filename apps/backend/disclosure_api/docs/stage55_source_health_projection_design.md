# Stage 5.5 source health projection design

This document defines a docs-only projection design for provider source health after the Stage 5.5 provider health state contract and offline health evaluator were locked.

This is a design document only. It does not add runtime projection code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 24c4ae0142fcd6d176ad2aa800b20af525c22c33
base source: PR #106 Add Stage 5.5 offline provider health evaluator
stage: Stage 5.5 PR D source health projection design
status: docs-only
locked health state contract: Stage55ProviderHealthState
locked offline evaluator: Stage55OfflineProviderHealthEvaluator
locked source health functions: Sources.list_source_health/1 and Sources.get_source_health/1
locked live fetch state: out of scope and default-off
```

## Goal

Define how provider source health should be projected for operators without changing public feed/API response shapes.

The first projection should be additive, operator-oriented, and internal. It should not introduce new public routes in this PR.

## Non-goals

This PR does not authorize:

```text
new public routes
feed/controller changes
runtime projection code
source registry schema changes
migrations
scheduler changes
live provider fetch
provider credentials
materializer changes
canonical mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Existing source health baseline

The current source layer already has internal source health functions:

```text
DisclosureAutomation.Sources.list_source_health/1
DisclosureAutomation.Sources.get_source_health/1
```

These functions can list source registry health metadata and retrieve a source plus cursors. Future projection work should prefer extending or composing this internal operator path before adding any new public API contract.

## Projection principle

Provider health projection is advisory and must not affect canonical data.

Required principles:

```text
projection does not mutate source health
projection does not mutate canonical_feed_items
projection does not create provider canonical feed items
projection does not create news-only canonical events
projection does not trigger live fetch
projection does not trigger scheduler work
projection does not change feed/API item shapes
projection exposes only redacted, bounded health diagnostics
```

## Recommended first projection shape

Future implementation may define an internal, operator-only projection shape like:

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

Disallowed fields:

```text
request headers
response headers
provider credentials
Authorization values
Cookie values
Subscription-Key values
signed private URLs
raw provider response bodies
full article text
unbounded provider error payloads
```

## Existing endpoint policy

This design does not add a route. A future implementation should first evaluate whether existing internal source health surfaces are sufficient.

Allowed future options, in order of preference:

```text
1. internal operator diagnostics using existing source health functions
2. additive test-only projection for unit/integration validation
3. docs-only API contract for a future operator-only endpoint
4. public route only after a separate design and security review
```

Disallowed in the first implementation:

```text
public unauthenticated source health endpoint
feed response source health fields
event detail response source health fields
GET request side effects
live fetch from projection call
scheduler trigger from projection call
```

## Response-shape guardrail

Locked response shapes must remain unchanged:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

The projection must not change:

```text
feed item_count
feed item ordering
official TDnet fields
official citations
overlay citation separation
top-level API envelopes
```

## Redaction policy

Projection output must be redacted by construction.

Never expose:

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
```

Allowed projected diagnostics remain bounded:

```text
provider
source_key
status
status_code
retry_count
timeout
error_class
last_checked_at
last_success_at
last_failure_at
request_id_hash
redaction_status
manual_review_reason
```

## Failure isolation policy

Provider health projection must be read-only and failure-isolated.

Required behavior for future implementation:

```text
projection failure does not affect TDnet runtime
projection failure does not affect feed serving
projection failure does not delete overlays
projection failure does not change provider health state
projection failure returns redacted error only
```

## Manual review policy

If projected health state is `manual_review_required`, the projection may include a redacted reason.

Allowed reasons:

```text
ambiguous_match
missing_match
conflict
redaction_violation
operator_pause
```

Disallowed evidence:

```text
raw provider article body
raw provider response
request headers
credentials
signed URLs
```

## Future implementation evidence

Any future source health projection implementation PR must prove:

```text
projection is read-only
projection is operator-only or test-only
projection contains no secrets
projection contains no full article text
projection does not trigger live fetch
projection does not trigger scheduler work
projection does not change feed/API shapes
projection does not mutate canonical items
projection preserves Stage 5.5 state/evaluator regressions
projection preserves Stage 5.4 offline staging regressions
```

## Stop conditions

Do not merge a source health projection implementation if it:

```text
adds public route without separate design
adds feed/controller source health fields
triggers live provider fetch
triggers scheduler work
stores or exposes provider credentials
stores or exposes request/response headers
stores or exposes full article text
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
breaks redaction checks
```
