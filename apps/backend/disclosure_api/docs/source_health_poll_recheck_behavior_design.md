# Source health poll/recheck behavior design

This document defines a docs-only behavior design for the existing source health recheck and source poll routes after the source health route contract lock design was merged.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: e1619a9c5f8b2446ed5eb54ff1402282118f111d
base source: PR #181 Design source health route contract lock
stream: source health poll/recheck behavior design
status: docs-only design
```

## Existing route surface

This design covers only existing routes:

```text
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

This design does not add, remove, rename, or repurpose any route.

## Design decision

Treat recheck and poll as different operator operations:

```text
recheck_source_health: bounded internal state evaluation; no external network by default
poll_source: high-risk source collection request; must remain gated before operational use
```

This PR does not implement either behavior. It defines the behavior gate that future implementation must satisfy.

## Recheck behavior model

Recheck should be the safer operator operation.

Default allowed behavior for recheck:

```text
validate operator authorization
validate source_key shape or allowlist
record bounded request metadata if implementation supports it
inspect existing stored source health metadata
return bounded source health status/result metadata
avoid public response changes
avoid canonical mutation
avoid provider/scheduler/materializer side effects
```

Default forbidden behavior for recheck:

```text
live provider fetch
provider client call
scheduler enqueue
source poll
source materialization
overlay materialization
canonical materialization
canonical mutation
public API/feed response mutation
raw provider payload rendering
secret/header/cookie rendering
unbounded diagnostics
```

If future implementation wants recheck to do more than stored-state evaluation, it must open a separate implementation design first.

## Poll behavior model

Poll is higher risk because it may be connected to external collection behavior.

Poll must not be treated as routine remediation until a concrete implementation contract is locked.

A future poll implementation must state:

```text
source_key allowlist
operator permission model
idempotency model
rate limit model
external network behavior
provider client interaction
scheduler interaction
materializer interaction
canonical impact
public response impact
stored private provider material impact
test plan
rollback plan
```

Default allowed behavior for poll before such a contract is locked:

```text
validate operator authorization
validate source_key shape or allowlist
return bounded accepted/rejected metadata
avoid public response changes
avoid canonical mutation
avoid implicit provider/scheduler/materializer side effects
```

Default forbidden behavior for poll before such a contract is locked:

```text
unbounded live provider fetch
unbounded provider client calls
implicit scheduler enqueue
implicit materializer execution
canonical mutation
public API/feed response mutation
secret/header/cookie rendering
raw provider payload rendering
full article text rendering
unbounded diagnostics
```

## Operation mapping

Route-derived operation remains authoritative:

```text
POST /api/admin/source-health/:source_key/recheck -> recheck_source_health
POST /api/admin/sources/:source_key/poll -> poll_source
```

Request body must not override route-derived operation.

Forbidden request body fields:

```text
operation
action_operation
route_operation
poll_operation
recheck_operation
```

## Request allowlist

Allowed bounded request metadata for both operations:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Forbidden request material:

```text
raw actor identifier
raw request identifier
raw idempotency key
unredacted reason
provider payload
secret
header
cookie
full article text
canonical payload
private transport material
unbounded diagnostics
```

## Response allowlist

Allowed bounded response fields:

```text
source_key
operation
required_permission
authorized
accepted
result_status
request_id_hash
idempotency_key_hash
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

Optional bounded response fields:

```text
last_checked_at
last_success_at
last_failure_at
last_error_code
retry_after
freshness_status
failure_code
```

Forbidden response material:

```text
raw provider payload
full article text
request headers
cookies
secrets
API keys
raw transport responses
SQL details
stack traces
canonical payloads
private actor context
unbounded diagnostics
```

## Authorization model

Backend authorization remains authoritative.

Candidate permissions:

```text
source_health:recheck
source:poll
```

Read-only permission must not authorize recheck or poll:

```text
source_health:read
```

Client-side or documentation affordances are advisory only.

## Idempotency model

Candidate identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Rate limit model

Future poll behavior must define rate limits before operational use.

Minimum poll rate-limit design fields:

```text
per source_key limit
per actor limit
global limit
retry_after semantics
failure response shape
operator override policy
```

Recheck may use lighter limits, but must still avoid unbounded operator-triggered loops.

## Public response-shape guardrails

Poll/recheck behavior must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
public API envelope
public feed envelope
feed ordering
feed item_count
official TDnet fields
official citations
```

## Canonical no-mutation guardrails

Poll/recheck behavior must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

unless a separate canonical-impact design explicitly approves the behavior.

## Provider, scheduler, and materializer guardrails

This design does not approve:

```text
live provider fetch
provider client calls
scheduler enqueueing
stored private provider material
source materialization
overlay materialization
canonical materialization
materializer behavior changes
```

Future poll implementation must explicitly state which of these are allowed, if any.

## Test gate for future implementation

Before runtime behavior changes, tests must prove:

```text
recheck does not call provider clients by default
recheck does not enqueue scheduler work by default
recheck does not trigger materializers by default
recheck does not mutate canonical data
poll behavior is explicit and bounded
request body cannot override route-derived operation
read-only permission cannot recheck or poll
bounded responses exclude raw/private material
public response-shape flags remain false unless explicitly approved
canonical mutation flags remain false unless explicitly approved
provider/scheduler/materializer flags are accurate
```

## Stop conditions

Stop and re-scope if implementation work:

```text
changes public response shapes
adds public source health fields
adds new routes without design approval
allows request-body operation override
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
omits rate limiting for poll
omits idempotency for operator-triggered poll/recheck writes
```
