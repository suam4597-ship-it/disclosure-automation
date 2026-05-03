# Stage 6.2 duplicate group action route design

This document defines a docs-only design for future operator-only duplicate group action routes after Stage 6.1 action state storage was locked.

This PR is design-only. It does not add routes, controllers, UI code, action endpoints, runtime route handlers, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, schema changes, migrations, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 2d45e6c86d21d9f290ce870518fab934bb4fb74d
base source: PR #147 Lock Stage 6.1 duplicate group action state
stage: Stage 6.2 PR A duplicate group action route design
status: docs-only
locked Stage 5.9 read routes: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 6.0 authorization gate: pure operator/admin authorization for action previews
locked Stage 6.1 writer: internal transaction writer for action event and review state rows
```

## Goal

Define the future operator-only action routes before implementing any route, controller, or action endpoint code.

The future action routes should let an authorized operator record a bounded internal review action for a duplicate group using the Stage 6.1 writer.

## Non-goals

This design does not authorize or implement:

```text
router changes
controller modules
action endpoints
UI changes
public duplicate group fields
public API response-shape changes
public feed response-shape changes
scheduler work
provider clients
live provider fetch
materializer behavior changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
```

## Future route candidates

Recommended future operator-only routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The existing read-only routes remain separate:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Future action routes must not change read route response shapes unless separately designed.

## Route-to-operation mapping

```text
POST /api/admin/duplicate-groups/:group_id/confirm -> confirm_duplicate_group
POST /api/admin/duplicate-groups/:group_id/reject -> reject_duplicate_group
POST /api/admin/duplicate-groups/:group_id/mark-review -> mark_duplicate_group_needs_review
POST /api/admin/duplicate-groups/:group_id/clear-review-state -> clear_duplicate_group_review_state
```

Unknown operations or route aliases should be rejected.

## Request body design

Future action route request body should be bounded and redacted.

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

Required request body fields:

```text
actor_id_hash
actor_permissions
idempotency_key_hash
request_id_hash
operator_reason_redacted
```

The `group_id` must come from the URL path and must match the internal action request `group_id`.

The action operation must come from the route mapping, not from an untrusted arbitrary request body field.

## Actor context design

Future implementation must construct actor context for the authorization gate from bounded internal request metadata.

Required actor context:

```text
authenticated
roles
permissions
actor_id_hash
```

Allowed role values:

```text
operator
admin
```

Action permissions must remain action-specific:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Read-only permission must not authorize action routes:

```text
duplicate_group:read
```

## Service integration design

Future route implementation should call only:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
```

The future controller should not bypass:

```text
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
Stage60DuplicateGroupOperatorActionAuthorizationGate
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

The writer should remain responsible for authorization, transaction handling, event idempotency, and review state upsert.

## Response design

Future action route response must be internal/operator-only and bounded.

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

Required false guardrail flags:

```text
public_response_shape_mutation
public_api_duplicate_group_fields
public_feed_duplicate_group_fields
canonical_feed_mutation
provider_canonical_feed_item_creation
news_only_event_creation
official_event_merge
official_fact_override
official_citation_override
trigger_live_fetch
scheduler_enabled
enqueue_performed
materializer_triggered
ui_added
```

`network_access` must remain `forbidden`.

## Failure response design

Recommended future action route failure responses:

```text
401 or 403 for authentication/authorization failure
404 for missing or unauthorized-not-revealed group
400 for invalid bounded request body
409 for idempotency or state conflict
422 for invalid transition or changeset validation failure
```

All failure responses must be bounded and must not include raw request bodies, private actor context, SQL details, provider payloads, full text, canonical payloads, or unbounded diagnostics.

## Idempotency design

Future action routes must require idempotency key hash.

Locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Retrying the same request must not duplicate event rows.

A new idempotency key may create a new event and update the latest review state.

## Public response guardrails

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

Operator action state remains advisory internal metadata.

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

## Future implementation sequence

Recommended next steps:

```text
1. Docs-only action route design
2. Route/controller implementation for action endpoints
3. Targeted route tests for authorization, idempotency, bounded response, and no public/canonical regressions
4. Optional read route projection update for internal review state, if separately designed
5. Optional UI design after action route behavior is locked
```

This PR covers only step 1.

## Stop conditions

Do not merge a future action route implementation if it:

```text
bypasses Stage 6.1 writer
bypasses Stage 6.0 authorization gate
adds UI in the route PR
changes public response shapes
adds public action state fields
mutates canonical data
triggers provider/scheduler/live-fetch work
stores raw actor/request/idempotency identifiers
returns raw provider payloads or full text
returns unbounded diagnostics
```
