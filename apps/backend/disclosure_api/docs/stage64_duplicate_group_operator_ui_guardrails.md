# Stage 6.4 duplicate group operator UI guardrails

This checklist defines guardrails for future duplicate group operator UI/experience work.

This PR is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future work must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a798eed49c1e27c8fa7666d763695774a93d7fbc
base source: PR #154 Lock Stage 6.3 duplicate group review state read projection
```

## Scope guardrails

Stage 6.4 design covers only a future internal/operator-only UI experience.

This design does not implement UI code.

Future UI work must not change locked backend behavior unless a separate implementation PR explicitly scopes and tests the change.

## Existing API dependency guardrails

A future UI may depend only on existing internal/operator-only duplicate group APIs.

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

Future UI work must not require public route changes, provider route changes, scheduler route changes, materializer route changes, or canonical mutation routes.

## List view guardrails

A future list view may display bounded fields from admin list responses.

Allowed list review state metadata:

```text
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
review_state_summary.redaction_status
```

The list view must not display action event history.

The list view must use only existing bounded filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

## Detail view guardrails

A future detail view may display bounded group/member metadata, current review state, and latest action event summary from admin show responses.

Allowed current review state fields:

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

Allowed latest action event summary fields:

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

The UI must not request, display, or reconstruct unbounded action history.

## Action control guardrails

Future action controls must map one button to one locked action route.

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The request body must not override route-derived action operation.

Read-only permission must not enable action controls:

```text
duplicate_group:read
```

Action controls must require action-specific permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

## Action request guardrails

Future UI action requests may send only bounded and already-redacted metadata.

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

The UI must not send raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, provider payloads, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Idempotency guardrails

Future UI action submissions must preserve server idempotency.

Locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

A future UI may prevent duplicate clicks, but server-side idempotency remains authoritative.

## Authorization guardrails

A future UI must be internal/operator-only.

Client-side authorization must be treated as presentation only. Backend authorization remains authoritative.

Future UI work must not bypass:

```text
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage61DuplicateGroupActionStateWriter
```

## Failure display guardrails

Future UI error displays must remain bounded.

Allowed categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Failure displays must not show SQL details, raw request bodies, private actor context, provider payloads, full text, canonical payloads, headers, cookies, secrets, or unbounded diagnostics.

## Forbidden display material

Future UI must not display:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
SQL details
provider secrets
request headers
cookies
raw transport metadata
```

## Public response-shape guardrails

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

## Validation guardrails for future implementation

Future implementation PRs should verify:

```text
changed files are limited to UI/frontend files and targeted tests unless justified
existing admin read/action route behavior is preserved
read-only users cannot trigger actions
action buttons map to locked routes only
request body cannot override route-derived operation
idempotency key hash is submitted for action attempts
review_state_summary display is bounded
action_event_summary display is show-only and bounded
no public response shape changes
no canonical mutation
no provider/scheduler/live-fetch behavior
materializer behavior is unchanged
changed-file strict redaction check passes
```
