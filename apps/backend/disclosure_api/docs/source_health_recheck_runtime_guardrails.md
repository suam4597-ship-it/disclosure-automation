# Source health recheck runtime guardrails

This checklist defines guardrails for the source health recheck runtime design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 5af195aa1847bffdad8cc64f532b02aaf44e0a90
base source: PR #187 Lock source health route contract tests
```

## Target route guardrails

This design covers only:

```text
POST /api/admin/source-health/:source_key/recheck
```

Do not add, remove, rename, or repurpose routes.

## Operation guardrails

Route-derived operation remains authoritative:

```text
recheck_source_health
```

Request body must not override operation.

Forbidden override fields:

```text
operation
action_operation
route_operation
recheck_operation
poll_operation
```

## Default behavior guardrails

Recheck should be bounded stored-state evaluation by default.

Allowed default behavior:

```text
validate operator authorization
validate source_key shape or allowlist
validate bounded request metadata
read existing source health state
compute bounded freshness/status result
return bounded response metadata
```

Forbidden default behavior:

```text
call provider clients
perform live provider fetch
enqueue scheduler work
trigger source poll
trigger materializers
mutate canonical data
change public responses
store raw provider payloads
return raw/private material
return unbounded diagnostics
```

## Request guardrails

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

## Response guardrails

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

## Authorization guardrails

Backend authorization remains authoritative.

Candidate required permission:

```text
source_health:recheck
```

Read-only permission must not authorize recheck:

```text
source_health:read
```

Rejected requests must not write action/audit state unless separately designed.

## Idempotency guardrails

If recheck introduces writes, idempotency must be defined before implementation.

Candidate identity:

```text
source_key + recheck_source_health + actor_id_hash + idempotency_key_hash
```

Same intended retry should reuse the same idempotency key hash.

New intended recheck should use a new idempotency key hash.

## Source key guardrails

Validate source_key before work.

Candidate validation:

```text
non-empty string
bounded length
known source allowlist or configured source registry
no path traversal semantics
no raw URL semantics unless explicitly allowed
```

Invalid source_key responses must remain bounded.

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
