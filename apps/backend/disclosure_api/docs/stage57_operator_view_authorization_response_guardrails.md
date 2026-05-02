# Stage 5.7 operator view authorization and response guardrails

This document defines authorization and response-shape guardrails for a future provider source health operator view.

This is a documentation-only guardrail file. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, UI behavior changes, or canonical feed mutations.

## Baseline

```text
base source: PR #113 Lock Stage 5.6 manual live provider integration
locked provider health: advisory, redacted, non-canonical
locked manual provider integration: operator-only, fake/default-off, metadata-only
locked response shapes: item.overlays[] and news_overlays[]
```

## Mandatory operator-only guardrail

Future implementation must restrict the view to operator/admin contexts.

Required:

```text
operator/admin authorization required
unauthenticated access forbidden
public API exposure forbidden without separate design
read-only permission separated from action permissions
action audit trail required if actions are added later
```

Disallowed:

```text
public unauthenticated route
public feed endpoint exposure
public event detail exposure
implicit access through existing feed/API responses
```

## Mandatory read-only guardrail

The first operator view implementation must be read-only.

Allowed:

```text
list source health
show source health detail
filter by health_status/source_type/active
show redacted cursor summary
show redacted diagnostics summary
```

Disallowed in first implementation:

```text
enqueue provider health recheck
run manual provider trigger
pause/unpause provider
clear redaction violation
acknowledge manual review
mutate source health
mutate canonical feed items
```

## Mandatory no-side-effect guardrail

Viewing source health must not trigger work.

Forbidden side effects:

```text
provider live fetch
scheduler enqueue
source health recompute
manual trigger invocation
raw staging
materialization
canonical feed mutation
overlay deletion
```

## Mandatory response-shape guardrail

Operator view must not alter locked public response shapes:

```text
read model: item.overlays[]
event overlay API: item.overlays[]
feed digest: news_overlays[]
```

Do not add source health fields to:

```text
feed items
event overlay API items
canonical feed items
public overlay citations
public top-level API envelopes
```

## Mandatory redaction guardrail

Operator view output must never expose:

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

Allowed bounded fields:

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
error_class
redaction_status
manual_review_reason
request_id_hash
cursor_keys
```

## Mandatory failure-isolation guardrail

Operator view failures must be isolated.

Required behavior:

```text
view failure does not affect TDnet runtime
view failure does not affect provider staging
view failure does not affect feed/API serving
view failure does not mutate source health
view failure does not delete overlays
view failure does not mutate canonical feed items
view failure returns bounded redacted error only
```

## Future action guardrail

If future work adds actions, those actions must be separate from read-only view work.

Action examples requiring separate design:

```text
enqueue source health recheck
run manual provider trigger
pause/unpause provider
acknowledge manual review
clear redaction violation
```

Future actions must require:

```text
operator/admin authorization
separate permission from read-only view
audit trail
idempotency rules
redaction checks
failure isolation
```

## Stop conditions

Do not merge a future operator view implementation if it:

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
stores or exposes request/response headers
stores or exposes full article text
breaks locked response shapes
breaks redaction checks
```
