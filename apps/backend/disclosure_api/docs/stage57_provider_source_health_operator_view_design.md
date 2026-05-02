# Stage 5.7 provider source health operator view design

This document defines a docs-only design for an operator-only provider source health view after Stage 5.6 locked the manual provider integration seam.

This is a design document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, UI behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c8d435a639053a7ebb430c5779a4515ec2231bee
base source: PR #113 Lock Stage 5.6 manual live provider integration
stage: Stage 5.7 provider source health operator view design
status: docs-only
locked provider health: advisory, redacted, non-canonical
locked manual provider integration: operator-only, fake/default-off, metadata-only
locked public response shapes: item.overlays[] and news_overlays[]
```

## Goal

Stage 5.7 should define how provider source health can be viewed by operators without changing public feed/API response shapes or triggering provider work.

The first operator view implementation must be:

```text
operator-only
read-only
redacted
advisory-only
non-canonical
no live fetch side effects
no scheduler side effects
no feed/API shape changes
```

## Non-goals

This PR does not authorize:

```text
new runtime route
public API route
UI implementation
provider live fetch
provider credentials
scheduler-triggered provider work
runtime projection code
migrations
schema changes
feed/controller changes
materializer changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Existing source health baseline

The codebase already has internal source health functions that future work may use or wrap:

```text
DisclosureAutomation.Sources.list_source_health/1
DisclosureAutomation.Sources.get_source_health/1
DisclosureAutomation.Sources.enqueue_source_health_recheck/1
DisclosureAutomation.Sources.recompute_source_health/1
```

Stage 5.7 operator view design should prefer read-only listing/details first. Recheck or recompute actions require separate implementation scope and review because they can enqueue work or mutate source health state.

## Operator view principle

The operator view is not a public feed or event-detail feature.

Required principles:

```text
view is restricted to operator/admin context
view is read-only by default
view shows redacted source health only
view does not trigger provider fetch
view does not trigger scheduler
view does not mutate canonical data
view does not add fields to public feed/API responses
```

## Recommended first view shape

The first operator view may show bounded redacted fields:

```text
source_key
display_name
provider
source_type
active
health_status
last_success_at
last_failure_at
last_seen_published_at
last_error_class
redaction_status
manual_review_reason
cursor_keys
has_recent_safe_overlay
```

Forbidden fields:

```text
provider credentials
request headers
response headers
raw provider response bodies
full article text
signed private URLs
unbounded error payloads
```

## Health status policy

The view may display the Stage 5.5 health state allowlist:

```text
unknown
healthy
degraded
rate_limited
timeout
failed
paused
redaction_violation
manual_review_required
```

The view must not convert provider health into canonical facts.

## Action policy

Initial operator view should be read-only. Any future action must be separately designed.

Read-only allowed:

```text
list sources by health_status
filter sources by active/source_type/region
show source detail with cursors
show redacted diagnostics summary
```

Requires separate design:

```text
enqueue source health recheck
manual provider invocation
pause/unpause provider
acknowledge manual review
clear redaction violation
```

## Public response-shape policy

The operator view must not alter locked public shapes:

```text
read model: item.overlays[]
event overlay API: item.overlays[]
feed digest: news_overlays[]
```

It must not add source health fields to:

```text
feed items
event overlay API items
canonical feed items
public overlay citations
public top-level API envelopes
```

## Redaction policy

Operator view output must be redacted by construction.

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
unbounded provider error payloads
```

Allowed redacted diagnostics:

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

## Failure isolation policy

Operator view failure must not affect ingestion or serving.

Required behavior for future implementation:

```text
operator view failure does not affect TDnet runtime
operator view failure does not affect feed/API serving
operator view failure does not mutate source health
operator view failure does not delete overlays
operator view failure does not mutate canonical feed items
operator view failure returns bounded redacted error only
```

## Authorization policy

A future implementation must be operator/admin-only. It must not be public by default.

Minimum future requirements:

```text
operator/admin authorization required
unauthenticated access forbidden
public API exposure forbidden without separate design
read-only permission separated from action permissions
action audit trail required if actions are added later
```

## Future implementation evidence

A future operator view implementation PR must prove:

```text
view is operator-only
view is read-only by default
view output is redacted
view does not trigger live fetch
view does not trigger scheduler
view does not mutate source health unless separately scoped
view does not mutate canonical feed items
view does not change feed/API response shapes
Stage 5.6 adapter regressions pass
Stage 5.5 health regressions pass
Stage 5.4 boundary/staging regressions pass
redaction checks pass
```

## Stop conditions

Do not merge a future operator view implementation if it:

```text
adds unauthenticated or public access
adds public feed/API source health fields
triggers provider live fetch
triggers scheduler work
stores or exposes credentials
stores or exposes request or response headers
stores or exposes full article text
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
breaks redaction checks
```
