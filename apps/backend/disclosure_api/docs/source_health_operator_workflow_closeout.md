# Source health operator workflow close-out

This document closes out the source health operator workflow documentation stream after the workflow design, operator runbook, route contract lock, and poll/recheck behavior design were merged.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 9f3880143e6b68a0d08098d0129fdec0b11bec4b
base source: PR #182 Design source health poll and recheck behavior
stream: source health operator workflow close-out
status: docs-only
```

## Evidence

```text
PR #179 Design source health operator workflow
scope: docs-only workflow design, guardrails, manual smoke

PR #180 Add source health operator runbook
scope: docs-only operator runbook, guardrails, manual smoke

PR #181 Design source health route contract lock
scope: docs-only route contract design, guardrails, manual smoke

PR #182 Design source health poll and recheck behavior
scope: docs-only poll/recheck behavior design, guardrails, manual smoke
```

## Locked route surface

The source health operator workflow is scoped to existing routes only:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

No route was added, removed, renamed, or repurposed by this documentation stream.

## Locked operator intent

Allowed operator intents remain:

```text
view bounded source health list
view bounded source health detail
request bounded source health recheck when authorized
request source poll only when current behavior and authorization allow it
inspect bounded status/result metadata
escalate stale or unhealthy source state using bounded metadata
```

Forbidden operator behavior remains:

```text
manual DB writes
manual canonical edits
manual provider payload edits
manual scheduler queue manipulation
manual materializer triggering outside approved route behavior
copying raw provider payloads into tickets
displaying secrets, headers, cookies, or tokens
using public routes for operator checks
```

## Locked read contract

Candidate bounded read fields remain:

```text
source_key
status
last_success_at
last_failure_at
last_checked_at
last_error_code
retry_after
freshness_status
redaction_status
```

Forbidden read response material remains:

```text
raw provider payload
full article text
request headers
cookies
secrets
API keys
raw transport responses
unbounded stack traces
SQL details
canonical payloads
private actor context
unbounded diagnostics
```

## Locked recheck behavior boundary

Recheck remains the safer operation.

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

## Locked poll behavior boundary

Poll remains high-risk and must not be treated as routine remediation until a concrete implementation contract is locked.

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

Default forbidden behavior before a contract is locked:

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

## Locked operation mapping

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

## Locked request allowlist

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

## Locked response allowlist

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

## Locked authorization and idempotency

Backend authorization remains authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only permission must not authorize recheck or poll:

```text
source_health:read
```

Candidate idempotency identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

## Locked public response-shape guardrails

Source health operator work must not change:

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

## Locked canonical no-mutation guardrails

Source health operator work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Locked provider, scheduler, and materializer guardrails

This documentation stream does not approve:

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

## Future implementation gates

Before runtime source health route work, create a scoped implementation proposal that states:

```text
affected routes
request fields
response fields
operator permission model
idempotency model
rate limits
external network behavior
scheduler interaction
provider client interaction
materializer interaction
canonical impact
public response impact
redaction impact
test plan
rollback plan
```

## Stop conditions

Stop and re-scope future source health work if it:

```text
changes public response shapes
adds public source health fields
adds new routes without design approval
changes poll/recheck side effects without design approval
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

## Validation

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_operator_workflow_closeout.md
```

No local test run is required unless a reviewer asks for targeted checks.
