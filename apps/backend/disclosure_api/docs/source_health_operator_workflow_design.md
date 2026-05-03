# Source health operator workflow design

This document starts a new docs-only stream after the duplicate group stream was paused in Stage 6.9.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0901a0ed7c7fccf26b5c768bfaab4ce248361073
base source: PR #178 Lock Stage 6.9 duplicate group pause decision
stream: source health operator workflow
status: docs-only design
```

## Existing route surface

The router currently exposes these source health/operator routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

This design does not add, remove, or change any route.

## Purpose

The source health stream should define operator-facing procedures for checking source health and triggering bounded recheck/poll operations without changing public responses or canonical data.

The first implementation track must begin with documentation and guardrails because source health and polling are high-risk operational surfaces.

## Non-goals

This design does not authorize:

```text
new routes
new public APIs
new public feed fields
new provider clients
new live fetch behavior
new scheduler behavior
new materializer behavior
new canonical mutations
new migrations
new schemas
new UI routes
new frontend framework or asset pipeline
manual DB writes
unbounded diagnostics
secret/header/cookie rendering
```

## Operator workflow boundaries

Allowed operator intents:

```text
view bounded source health list
view bounded source health detail
request bounded recheck for a source
request bounded poll for a source
inspect bounded status/result metadata
escalate when a source appears stale or unhealthy
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

## Read route design

List route:

```text
GET /api/admin/source-health
```

Detail route:

```text
GET /api/admin/source-health/:source_key
```

Future operator docs/tests should verify bounded responses only.

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

## Recheck route design

Existing route:

```text
POST /api/admin/source-health/:source_key/recheck
```

A recheck should be treated as a bounded operator request that evaluates stored/internal source health state.

This design does not authorize live provider fetch, scheduler enqueue, materializer execution, or canonical mutation from a recheck route unless a later implementation design explicitly approves it.

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
```

## Poll route design

Existing route:

```text
POST /api/admin/sources/:source_key/poll
```

Polling is a higher-risk operation than recheck because it may be connected to external source collection or source runtime behavior.

This docs-only design does not approve any new poll side effects. Future implementation or runbook work must state exactly whether poll is no-op, stored-only, scheduler-backed, provider-backed, or live-fetch-backed.

Before poll behavior is changed or relied upon operationally, require a separate poll behavior design that states:

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

## Authorization design

Backend authorization must remain authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only source health permission must not authorize recheck or poll.

Client-side affordances, if any, are advisory only.

## Idempotency design

Future recheck/poll requests should define idempotency before implementation.

Candidate identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Public response guardrails

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

unless a separate canonical-impact design explicitly approves such behavior.

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

Future poll/recheck work must explicitly state if it needs any of these.

## Recommended implementation sequence

```text
PR A: source health operator workflow design
PR B: source health operator runbook
PR C: source health route contract tests or docs lock
PR D: source poll/recheck behavior design
PR E: source health stream close-out
```

This PR is PR A only.

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
