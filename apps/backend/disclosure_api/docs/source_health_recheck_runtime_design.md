# Source health recheck runtime design

This document defines a docs-only runtime design for the existing source health recheck route after source health route contract tests were locked.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 5af195aa1847bffdad8cc64f532b02aaf44e0a90
base source: PR #187 Lock source health route contract tests
stream: source health recheck runtime design
status: docs-only design
```

## Target route

This design covers only the existing route:

```text
POST /api/admin/source-health/:source_key/recheck
```

No route is added, removed, renamed, or repurposed.

## Design decision

Recheck should be implemented as a bounded stored-state evaluation by default.

Recheck must not perform live external collection unless a later design explicitly changes this policy.

Default operation:

```text
recheck_source_health
```

The route-derived operation remains authoritative. The request body must not override the operation.

## Allowed runtime behavior

A future recheck implementation may:

```text
validate source_key shape
validate source_key allowlist if one exists
validate backend authorization
validate bounded request metadata
apply idempotency if writes are introduced
read existing source health state
compute bounded freshness/status result
return bounded response metadata
record bounded audit/action event only if separately designed
```

## Forbidden runtime behavior

A future recheck implementation must not, by default:

```text
call provider clients
perform live provider fetch
enqueue scheduler work
trigger source poll
trigger source materialization
trigger overlay materialization
trigger canonical materialization
mutate canonical_feed_items
mutate news_overlay_attachments
change public API response shapes
change public feed response shapes
store raw provider payloads
return raw provider payloads
return full article text
return secrets, headers, cookies, or tokens
return SQL details or stack traces
return unbounded diagnostics
```

## Request allowlist

Allowed request fields:

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

Forbidden request fields:

```text
operation
action_operation
route_operation
recheck_operation
poll_operation
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
provider_payload
secret
header
cookie
full_article_text
canonical_payload
private_transport_material
unbounded_diagnostics
```

## Response allowlist

Allowed response fields:

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

Forbidden response fields:

```text
raw_provider_payload
full_article_text
headers
cookies
secrets
api_keys
raw_transport_response
sql_details
stack_trace
canonical_payload
private_actor_context
unbounded_diagnostics
```

## Authorization model

Backend authorization remains authoritative.

Candidate required permission:

```text
source_health:recheck
```

Read-only permission must not authorize recheck:

```text
source_health:read
```

Rejected requests must not write action/audit state unless a separate failure-audit design approves it.

## Idempotency model

If recheck introduces writes, idempotency must be defined before implementation.

Candidate identity:

```text
source_key + recheck_source_health + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended recheck should use a new idempotency key hash.

If the first recheck implementation is read-only, it may still require idempotency metadata for future compatibility, but it must state whether that metadata is recorded.

## Source key validation

Future implementation should validate source_key before doing any work.

Candidate validation:

```text
non-empty string
bounded length
known source allowlist or configured source registry
no path traversal semantics
no raw URL semantics unless explicitly allowed
```

Invalid source_key responses must remain bounded and must not reveal registry internals or SQL details.

## Freshness/status computation

Default recheck may compute source health from existing stored metadata only.

Candidate fields used for computation:

```text
last_success_at
last_failure_at
last_checked_at
last_error_code
retry_after
freshness_status
status
```

The computation must not fetch provider data or materialize new records by default.

## Public response-shape guardrails

Recheck runtime work must not change:

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

Recheck runtime work must not:

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

## Future implementation test plan

A future implementation PR should test:

```text
route exists and maps to recheck action
request body cannot override operation
bounded request allowlist is enforced
read-only permission is rejected
source_health:recheck permission is accepted
invalid source_key is bounded
response includes only allowlisted fields
raw/private fields are absent
public response-shape flags remain false
canonical mutation flags remain false
provider/scheduler/materializer flags remain false
no provider client call occurs
no scheduler enqueue occurs
no materializer call occurs
no canonical mutation occurs
```

## Rollback plan

If a future implementation causes unexpected side effects:

```text
disable or revert the recheck action implementation
preserve read-only source health routes
keep route contract tests
confirm public responses remain unchanged
confirm canonical data remains unchanged
confirm provider/scheduler/materializer side effects are absent
```

## Stop conditions

Stop and re-scope if recheck implementation:

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
omits authorization
omits idempotency decision if writes are introduced
```
