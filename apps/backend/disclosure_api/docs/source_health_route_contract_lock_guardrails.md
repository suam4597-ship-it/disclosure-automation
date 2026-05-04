# Source health route contract lock guardrails

This checklist defines guardrails for the source health route contract lock design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a04edff25e0d2293b6341eb172f72898a7a4ce4b
base source: PR #180 Add source health operator runbook
```

## Route surface guardrails

Allowed existing routes only:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Do not add, remove, rename, or repurpose routes in this design PR.

## Read route guardrails

Candidate bounded fields:

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
headers
cookies
secrets
API keys
raw transport response
SQL details
stack traces
canonical payload
private actor context
unbounded diagnostics
```

## Recheck route guardrails

Existing route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Request body must not override route-derived operation:

```text
recheck -> recheck_source_health
```

This design does not approve:

```text
live provider fetch
provider client calls
scheduler enqueue
materializer execution
canonical mutation
public response mutation
```

## Poll route guardrails

Existing route:

```text
POST /api/admin/sources/:source_key/poll
```

Request body must not override route-derived operation:

```text
poll -> poll_source
```

Do not rely on poll operationally until a later design states:

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

## Request allowlist guardrails

Candidate request allowlist:

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

## Authorization guardrails

Backend authorization remains authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only permission must not authorize recheck or poll.

## Idempotency guardrails

Candidate mutating operator identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Public response-shape guardrails

Source health route contract work must not change:

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

Source health route contract work must not:

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

Stop and re-scope if future route contract work:

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
```
