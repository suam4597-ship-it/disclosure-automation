# Source health poll/recheck behavior guardrails

This checklist defines guardrails for source health recheck and source poll behavior design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: e1619a9c5f8b2446ed5eb54ff1402282118f111d
base source: PR #181 Design source health route contract lock
```

## Route guardrails

This design covers only existing routes:

```text
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Do not add, remove, rename, or repurpose routes.

## Recheck guardrails

Recheck is the safer operation.

Default allowed behavior:

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

Default forbidden behavior:

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

## Poll guardrails

Poll is high-risk.

Poll must not be treated as routine remediation until a concrete implementation contract is locked.

Future poll implementation must state:

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

Default forbidden behavior before such a contract is locked:

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

## Operation mapping guardrails

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

## Request guardrails

Allowed bounded request metadata:

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

## Response guardrails

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

## Authorization guardrails

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

## Idempotency guardrails

Candidate identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Rate limit guardrails

Future poll behavior must define:

```text
per source_key limit
per actor limit
global limit
retry_after semantics
failure response shape
operator override policy
```

Recheck must still avoid unbounded operator-triggered loops.

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
