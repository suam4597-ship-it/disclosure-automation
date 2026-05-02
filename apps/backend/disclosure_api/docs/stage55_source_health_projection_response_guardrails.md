# Stage 5.5 source health projection response guardrails

This document defines response-shape guardrails for any future Stage 5.5 source health projection implementation.

This is a documentation-only guardrail file. It does not add runtime projection code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base source: PR #106 Add Stage 5.5 offline provider health evaluator
locked health state contract: Stage55ProviderHealthState
locked offline health evaluator: Stage55OfflineProviderHealthEvaluator
locked official source: jp_tdnet_timely_disclosure
locked overlay behavior: metadata-only, attach-only, non-canonical
locked live fetch state: out of scope and default-off
```

## Locked public response shapes

Future source health projection must not change locked response shapes:

```text
read model: item.overlays[]
event overlay API: item.overlays[]
feed digest: news_overlays[]
```

It must not change:

```text
feed item_count
feed item ordering
official TDnet event id
official TDnet source key
official TDnet title/headline
official TDnet published_at
official TDnet official_source_url
official TDnet citations
overlay citation separation
top-level API response envelope
```

## Projection surface policy

The first implementation should prefer internal/operator-only projection.

Allowed future surfaces, in order:

```text
internal operator diagnostics using existing source health functions
test-only projection for validation
docs-only design for operator-only API contract
separate reviewed operator-only route
```

Disallowed without separate design:

```text
public unauthenticated route
feed item source health fields
event detail source health fields
GET-triggered health recomputation
GET-triggered live fetch
scheduler-triggered projection refresh
```

## Additive-only policy

If a future projection becomes part of an API, it must be additive and separately designed.

Allowed additive shape examples:

```text
operator_health.status
operator_health.last_checked_at
operator_health.redaction_status
operator_health.manual_review_reason
```

Disallowed changes:

```text
renaming existing fields
removing existing fields
changing existing field types
moving overlays out of item.overlays[]
moving feed overlays out of news_overlays[]
copying provider health into official TDnet canonical fields
```

## Redaction-by-response policy

Projection responses must never include:

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

Projection responses may include only redacted, bounded diagnostics:

```text
provider
source_key
health_status
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

## Failure response policy

Projection failures must be redacted and isolated.

Required behavior:

```text
projection failure does not fail TDnet runtime
projection failure does not fail feed/API serving
projection failure does not remove existing overlays
projection failure does not mutate source state unless separately scoped
projection failure does not mutate canonical feed items
projection failure returns bounded redacted error only
```

## Canonical no-mutation policy

Projection must not write canonical data.

Forbidden writes:

```text
canonical_feed_items official TDnet fields
provider canonical feed items
news-only canonical events
official citations
official source URL
official published_at
official stable_external_id
```

## Implementation evidence required later

Any future source health projection implementation PR must prove:

```text
locked response shapes unchanged
projection output redacted
projection is read-only unless separately scoped
projection does not trigger live fetch
projection does not trigger scheduler
projection does not mutate canonical feed items
projection does not delete overlays
Stage 5.5 health evaluator regression passes
Stage 5.4 offline staging regression passes
Stage 5.3 multi-overlay response contract passes
Stage 5 feed/API regressions pass
TDnet runtime/http regressions pass
```

## Stop conditions

Do not merge a future source health projection implementation if it:

```text
adds public route without separate design
adds source health fields to feed items without separate design
adds source health fields to event overlay API without separate design
triggers live provider fetch
triggers scheduler work
stores or exposes credentials
stores or exposes request/response headers
stores or exposes full article text
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
breaks redaction checks
```
