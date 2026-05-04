# Source health route contract lock design

This document defines a docs-only route contract lock design for the source health operator route surface after the source health operator runbook was merged.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a04edff25e0d2293b6341eb172f72898a7a4ce4b
base source: PR #180 Add source health operator runbook
stream: source health route contract lock design
status: docs-only design
```

## Locked existing route surface

The source health operator route contract is scoped to existing routes only:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

This design does not add, remove, rename, or repurpose any route.

## Contract purpose

The route contract lock should make future implementation/review work unambiguous about:

```text
operator-only route scope
bounded response fields
bounded request metadata
forbidden raw/private material
recheck side-effect boundaries
poll side-effect gates
public response-shape preservation
canonical no-mutation rules
provider/scheduler/materializer guardrails
```

## GET /api/admin/source-health contract

The list route should return bounded source health list metadata only.

Candidate response envelope:

```text
mode
route_added
ui_added
item_count
items[]
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

Candidate item fields:

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

List route must not include:

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

## GET /api/admin/source-health/:source_key contract

The detail route should return bounded metadata for one source.

Candidate response envelope:

```text
mode
route_added
ui_added
source_key
item
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

Candidate item fields:

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
bounded_recent_checks
bounded_failure_summary
```

Detail route must not include:

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

## POST /api/admin/source-health/:source_key/recheck contract

The recheck route should remain operator-only and bounded.

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

Candidate response fields:

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

The route-derived operation remains authoritative:

```text
recheck -> recheck_source_health
```

Request body must not override route-derived operation.

Recheck must not be assumed to perform:

```text
live provider fetch
provider client calls
scheduler enqueue
materializer execution
canonical mutation
public response mutation
```

unless a later implementation design explicitly changes that contract.

## POST /api/admin/sources/:source_key/poll contract

The poll route is high-risk and must remain explicitly bounded.

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

Candidate response fields:

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

The route-derived operation remains authoritative:

```text
poll -> poll_source
```

Request body must not override route-derived operation.

Before poll is treated as operational remediation, a separate behavior design must state:

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

## Authorization contract

Backend authorization remains authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only permission must not authorize recheck or poll.

## Idempotency contract

Candidate identity for mutating operator requests:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended operation should use a new idempotency key hash.

## Public response-shape contract

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

## Canonical no-mutation contract

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

## Provider, scheduler, and materializer contract

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

## Test plan for a future implementation PR

A future route contract test PR should verify:

```text
list route returns bounded fields only
detail route returns bounded fields only
recheck route accepts only bounded metadata
poll route accepts only bounded metadata
request body cannot override route-derived operation
read-only permission cannot recheck or poll
public response-shape flags remain false
canonical mutation flags remain false
provider/scheduler/materializer flags remain false or explicitly documented
raw/private materials are absent
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
