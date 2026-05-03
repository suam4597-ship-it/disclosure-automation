# Stage 6.0 duplicate group operator action permission checklist

This checklist defines permission and redaction guardrails for future duplicate group operator actions.

This is docs-only. It does not add runtime authorization code, action endpoints, routes, controllers, UI, audit writes, schema changes, migrations, provider clients, live fetch, scheduler work, public response changes, materializer changes, or canonical mutations.

## Permission separation

Read and action permissions must remain separate.

Read permission:

```text
duplicate_group:read
```

Action permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

A future implementation must reject action requests authorized only by `duplicate_group:read`.

## Actor context requirements

Future action requests must require bounded authenticated actor context:

```text
actor_id_hash
actor_roles
actor_permissions
request_id_hash
idempotency_key_hash
```

Allowed roles:

```text
operator
admin
```

Forbidden context fields:

```text
actor_id
actor_email
actor_name
request_id
idempotency_key
raw_session_id
raw_ip_address
```

## Action operation allowlist

Future action contracts should allow only:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Unknown action operations must be rejected.

## Action-to-permission mapping

```text
confirm_duplicate_group -> duplicate_group:confirm
reject_duplicate_group -> duplicate_group:reject
mark_duplicate_group_needs_review -> duplicate_group:mark_review
clear_duplicate_group_review_state -> duplicate_group:clear_review_state
```

Action requests must include the required permission for the requested operation.

## Required request fields

Future action requests should require:

```text
group_id
action_operation
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
```

Future action requests should reject:

```text
blank group_id
unknown action_operation
missing actor_id_hash
missing request_id_hash
missing idempotency_key_hash
missing operator_reason_redacted
unredacted operator_reason
```

## Bounded field policy

Suggested future maximum lengths:

```text
group_id: 160
action_operation: 80
actor_id_hash: 128
request_id_hash: 128
idempotency_key_hash: 128
operator_reason_redacted: 500
failure_code: 120
```

Hashes should be hash-shaped and redacted. Raw identifiers must not be accepted.

## Idempotency guardrails

Future action services should deduplicate action attempts by bounded idempotency identity:

```text
group_id
action_operation
actor_id_hash
idempotency_key_hash
```

Future action services must not use raw request body, raw operator identity, provider payloads, or full article text as idempotency inputs.

## Audit guardrails

Future audit event output should be bounded and redacted.

Allowed audit metadata:

```text
action_operation
group_id
actor_id_hash
request_id_hash
idempotency_key_hash
required_permission
result_status
pre_review_state
post_review_state
redacted_operator_reason
failure_code
redaction_status
created_at
```

Forbidden audit metadata:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
raw request body
raw provider bodies
full article text
provider secret values
provider transport metadata
canonical feed payloads
provider canonical creation payloads
unbounded diagnostics
```

## Route guardrails

Future action routes must be explicit action endpoints, separate from Stage 5.9 read routes.

Potential future routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

This checklist does not implement those routes.

## Response guardrails

Future action responses should return bounded internal operator metadata only:

```text
group_id
action_operation
result_status
pre_review_state
post_review_state
request_id_hash
idempotency_key_hash
redaction_status
canonical_feed_mutation: false
public_response_shape_mutation: false
```

Future action responses must not expose raw actor context, raw request body, provider material, full article text, canonical payloads, or unbounded diagnostics.

## Public response guardrails

Future action work must not change public response shapes:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
```

Public duplicate group fields must remain absent unless a separate public response-shape design changes that policy.

## Canonical no-mutation guardrails

Future duplicate group operator actions must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider and scheduler guardrails

Future duplicate group operator actions must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
read provider credentials
store provider credentials
store provider transport metadata
materialize duplicate groups
materialize overlays
```

## Validation checklist for future implementation

Future implementation PRs should verify:

```text
read permission does not authorize actions
action-specific permissions are enforced
unknown operations are rejected
raw actor/request/idempotency identifiers are rejected
operator reason is bounded and redacted
idempotency behavior is stable
bounded audit event is built
no public response shape mutation
no canonical mutation
no provider/scheduler/live-fetch behavior
changed-file strict redaction check passes
```
