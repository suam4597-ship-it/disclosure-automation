# Stage 6.4 duplicate group operator UI experience design

This document defines a docs-only design for a future duplicate group operator UI/experience after Stage 6.3 review state read projection behavior was locked.

This PR is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a798eed49c1e27c8fa7666d763695774a93d7fbc
base source: PR #154 Lock Stage 6.3 duplicate group review state read projection
stage: Stage 6.4 PR A duplicate group operator UI experience design
status: docs-only
locked Stage 5.9 read routes: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 6.2 action routes: POST /api/admin/duplicate-groups/:group_id/confirm, reject, mark-review, clear-review-state
locked Stage 6.3 read metadata: review_state_summary and show-only action_event_summary
```

## Purpose

Stage 6.4 defines how a future operator-facing UI should use the locked duplicate group read/action APIs without changing their behavior.

The future UI should help an operator:

```text
review duplicate group candidates
inspect bounded group/member metadata
see current review state
see bounded latest action history on the detail view
record confirm/reject/needs-review/clear-review actions
avoid public/canonical/provider side effects
```

## Non-goals

This design does not authorize or implement:

```text
frontend components
UI routes
backend runtime code
router changes
controller changes
action endpoint changes
write behavior changes
new action operations
new authorization rules
new migrations
new schema modules
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

## Existing API dependencies

A future UI may depend only on the existing internal/operator-only APIs.

Read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The future UI must not require new public routes, public API fields, provider routes, scheduler routes, materializer routes, or canonical mutation routes.

## Operator list view design

A future list view should show bounded duplicate group review rows from:

```text
GET /api/admin/duplicate-groups
```

Recommended columns:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
review_state_summary.redaction_status
```

Recommended list filters must remain limited to existing locked filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

The list view should not display action event history. The list view may display a compact current review state badge only.

## Operator detail view design

A future detail view should show one bounded duplicate group projection from:

```text
GET /api/admin/duplicate-groups/:group_id
```

Recommended sections:

```text
group summary
member summary table
current review state panel
latest action event summary panel
action control panel
redaction/guardrail notice
```

The detail view may display `action_event_summary` because Stage 6.3 locks it for show responses only.

The action event summary must remain bounded to the fields and latest-five limit already locked by Stage 6.3.

## Current review state display

A future UI may display these `review_state_summary` fields:

```text
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
```

A missing review state should render as an explicit neutral state, for example:

```text
review_state: not reviewed
last_action_operation: none
reviewed_at: none
review_reason_redacted: none
```

The UI must not create or backfill review state just to display a neutral state.

## Latest action event display

A future detail view may display these `action_event_summary` fields:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

The UI must not display `operator_reason_redacted` in action event history unless a separate design explicitly changes the locked response contract.

The UI must not request, reconstruct, or display raw actor identifiers, raw request identifiers, raw idempotency keys, raw provider payloads, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Action control design

Future action controls may be rendered as four explicit buttons:

```text
Confirm duplicate group
Reject duplicate group
Mark needs review
Clear review state
```

Each button maps to exactly one locked route:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The UI must not allow a request body field to override the route-derived action operation.

The UI should display the required permission next to each action:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Read-only permission must not enable action controls:

```text
duplicate_group:read
```

## Action request design

Future UI action requests must send only bounded, already-redacted action metadata accepted by the locked action routes.

Allowed action request fields:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

The UI must require an operator reason input but must submit only `operator_reason_redacted`.

The UI must generate or receive only hashed request/idempotency identifiers before submission.

## Idempotency design

Future UI action submissions must include a stable idempotency key hash per action attempt.

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI should prevent duplicate clicks while an action request is pending, but server-side idempotency remains the source of truth.

Retrying a failed or timed-out request should reuse the same idempotency key hash when the operator is retrying the same intended action.

## Authorization and visibility design

Future UI must be internal/operator-only.

Minimum display rules:

```text
unauthenticated users cannot access the UI
users without operator/admin role cannot access the UI
users with read-only permission may view read routes only
users without action-specific permission cannot trigger that action
```

The UI must not rely only on client-side authorization. Backend authorization remains required and authoritative.

## Failure state design

Future UI error surfaces must remain bounded.

Allowed user-facing failure categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Failure displays must not include SQL details, raw request bodies, private actor context, provider payloads, full text, canonical payloads, headers, cookies, secrets, or unbounded diagnostics.

## Refresh behavior

After a successful action, the UI should refresh:

```text
GET /api/admin/duplicate-groups/:group_id
```

Optional list refresh may call:

```text
GET /api/admin/duplicate-groups
```

Refresh behavior must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Public response guardrails

Future UI work must not change:

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

Public duplicate group review/action state fields must remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future UI work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

Operator review state remains internal advisory metadata.

## Provider, scheduler, and materializer guardrails

Future UI work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Implementation sequence

Recommended next steps after this docs-only design is verified:

```text
1. Stage 6.4 PR A: docs-only operator UI experience design
2. Stage 6.4 PR B: minimal internal UI shell or route design, if UI implementation is still desired
3. Stage 6.4 PR C: frontend implementation with targeted tests, if a UI codebase exists and is in scope
4. Stage 6.4 lock close-out after behavior and tests are verified
```

This PR covers only step 1.

## Stop conditions

Do not merge a future UI implementation if it:

```text
adds public duplicate group fields
changes public response shapes
changes action endpoint behavior
changes action write behavior
bypasses Stage 6.1 writer
bypasses Stage 6.0 authorization gate
allows request-body override of route-derived action operation
shows raw actor/request/idempotency identifiers
shows unredacted operator reasons
shows raw provider payloads or full article text
shows canonical payloads
returns unbounded diagnostics
mutates canonical data
triggers provider/scheduler/live-fetch work
changes materializer behavior
```
