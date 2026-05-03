# Stage 6.2 duplicate group action route guardrails

This checklist defines guardrails for future operator-only duplicate group action routes.

This PR is docs-only. It does not add router changes, controllers, UI code, action endpoints, runtime route handlers, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, schema changes, migrations, or canonical mutations.

## Route scope guardrails

Future action routes may be implemented only after this design is locked.

Candidate future routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Existing read routes remain read-only:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Future action route PRs must not change read route behavior unless separately designed.

## Action mapping guardrails

Future route handlers must map routes to locked operations:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

The request body must not override route-derived action operation.

## Request body guardrails

Allowed request body fields:

```text
actor_id_hash
actor_permissions
idempotency_key_hash
request_id_hash
operator_reason_redacted
redaction_status
result_status
pre_review_state
post_review_state
failure_code
created_at
```

Forbidden request body fields:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Authorization guardrails

Future action routes must require:

```text
authenticated actor context
operator or admin role
action-specific permission
actor_id_hash
```

Read-only permission must not authorize action routes:

```text
duplicate_group:read
```

Future route code must not bypass:

```text
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage61DuplicateGroupActionStateWriter
```

## Writer integration guardrails

Future route handlers should call the writer and let it enforce:

```text
action contract validation
audit event validation
authorization gate validation
changeset validation
transactional event/state writes
event idempotency
review state upsert
```

Future route handlers must not write directly to:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

## Response guardrails

Future route response should be bounded and internal/operator-only.

Allowed response fields:

```text
mode
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
redaction_status
pre_review_state
post_review_state
action_event_id
action_event_inserted
review_state_id
review_state
authorized
authorization_result
```

Future response must not include raw actor identity, raw request identity, raw idempotency key, private provider material, raw provider payload, full article text, canonical payload, or unbounded diagnostics.

## Failure guardrails

Future failure responses must be bounded.

Recommended statuses:

```text
401 or 403 for authentication/authorization failure
404 for not found or unauthorized-not-revealed group
400 for invalid bounded body
409 for idempotency/state conflict
422 for transition or changeset failure
```

Failure responses must not leak SQL details, private actor context, raw request body, provider material, or canonical payloads.

## Public response-shape guardrails

Future action routes must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

Public duplicate group action state fields must remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future action routes must not:

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

Future action routes must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Validation guardrails for future implementation

Future implementation PRs should verify:

```text
changed files are limited to route/controller/tests/manual smoke unless justified
only action POST routes are added
read routes are unchanged
routes call Stage61DuplicateGroupActionStateWriter
writer authorization and idempotency behavior is preserved
bounded success response only
bounded failure response only
no public response shape changes
no canonical mutation
no provider/scheduler/live-fetch behavior
changed-file strict redaction check passes
```
