# Source health operator workflow guardrails

This checklist defines guardrails for the source health operator workflow stream.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0901a0ed7c7fccf26b5c768bfaab4ce248361073
base source: PR #178 Lock Stage 6.9 duplicate group pause decision
stream: source health operator workflow
```

## Existing route guardrails

Existing source health/operator route surface:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

This stream must not add, remove, rename, or repurpose routes without a separate design PR.

## Scope guardrails

Allowed docs-only scope:

```text
operator workflow design
operator runbook design
bounded response expectations
redaction policy
poll/recheck behavior gates
manual smoke checklists
close-out documents
```

Forbidden in this design PR:

```text
runtime code
router changes
controller changes
tests
fixtures
migrations
schemas
templates
frontend code
provider clients
scheduler code
materializers
canonical behavior
public API/feed behavior
```

## Operator behavior guardrails

Allowed operator intents:

```text
view bounded source health list
view bounded source health detail
request bounded source health recheck
request bounded source poll only if existing route behavior allows it
inspect bounded status/result metadata
escalate stale or unhealthy source state
```

Forbidden operator behavior:

```text
manual DB writes
manual canonical edits
manual provider payload edits
manual scheduler queue manipulation
manual materializer triggering outside approved routes
copying raw provider payloads into tickets
displaying secrets, headers, cookies, or tokens
using public routes for operator checks
```

## Read response guardrails

Candidate bounded read fields:

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

Forbidden read response material:

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
```

## Recheck guardrails

Existing route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Recheck must remain bounded and operator-only.

This design does not approve:

```text
live provider fetch
scheduler enqueue
materializer execution
canonical mutation
public response mutation
```

Allowed bounded request metadata for a future design:

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
```

## Poll guardrails

Existing route:

```text
POST /api/admin/sources/:source_key/poll
```

Poll behavior must not be changed or relied on operationally until a separate poll behavior design states:

```text
source_key allowlist
operator permission model
idempotency model
rate limit model
external network behavior
scheduler interaction
provider client interaction
materializer interaction
canonical impact
public response impact
test plan
rollback plan
```

## Authorization guardrails

Backend authorization remains authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only source health permission must not authorize recheck or poll.

Client-side affordances, if any, are advisory only.

## Idempotency guardrails

Candidate identity for future recheck/poll writes:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Public response-shape guardrails

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

## Canonical no-mutation guardrails

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

## Provider, scheduler, and materializer guardrails

This stream must not introduce these without an explicit design gate:

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

Stop and re-scope if future source health work:

```text
changes public response shapes
adds public source health fields
adds new routes without design approval
changes poll/recheck side effects without design approval
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
```
