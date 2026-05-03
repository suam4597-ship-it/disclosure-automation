# Stage 6.7 duplicate group operator UI polish close-out

This document closes out Stage 6.7 duplicate group operator UI polish after the design, UI state implementation, action confirmation, permission-aware buttons, and accessibility/usability pass were merged.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c4f3f69de9bc4fafdbfa95c829ee71e6b362f1ba
base source: PR #172 Add Stage 6.7 duplicate group UI accessibility pass
stage: Stage 6.7 close-out
status: docs-only
```

## Stage 6.7 evidence

```text
PR #168 Design Stage 6.7 duplicate group operator UI polish
scope: docs-only design, guardrails, manual smoke

PR #169 Add Stage 6.7 duplicate group operator UI states
scope: bounded loading, empty, error, success states

PR #170 Add Stage 6.7 duplicate group action confirmation
scope: confirmation modal, cancel path, duplicate-click prevention

PR #171 Add Stage 6.7 duplicate group permission-aware buttons
scope: advisory permission-aware button states while preserving action flow

PR #172 Add Stage 6.7 duplicate group UI accessibility pass
scope: lightweight accessibility and usability hints
```

## Locked UI routes

Stage 6.7 keeps the Stage 6.6 UI route set unchanged:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

No public duplicate group UI route was added.

Forbidden namespaces remain:

```text
/public/duplicate-groups
/api/public/duplicate-groups
/api/events duplicate group fields
/api/feed duplicate group fields
provider callback routes
scheduler routes
materializer routes
canonical mutation routes
```

## Locked JSON API dependencies

Stage 6.7 keeps the JSON API dependencies unchanged:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

No alternate read, action, write, provider, scheduler, materializer, public, or canonical API was added.

## Locked list screen polish

The list screen keeps the locked Stage 6.6 behavior:

```text
GET /admin/duplicate-groups
GET /api/admin/duplicate-groups
```

Locked bounded list filters remain:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Locked list exclusions remain:

```text
action_event_summary
operator_reason_redacted action history
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

Stage 6.7 adds bounded list UI states only:

```text
ready
loading
loaded
empty
error
```

## Locked detail screen polish

The detail screen keeps the locked Stage 6.6 behavior:

```text
GET /admin/duplicate-groups/:group_id
GET /api/admin/duplicate-groups/:group_id
```

Stage 6.7 preserves:

```text
detail JSON load
show-response-only latest-five action_event_summary
confirmation modal
confirmed action POST
cancel path
bounded action result
action completion detail refresh
```

Stage 6.7 adds bounded detail UI states only:

```text
ready
loading
loaded
error
no review state recorded
no members found
no latest actions found
```

## Locked action confirmation behavior

Operator actions must still go through a confirmation step before submission.

Confirmation fields remain bounded:

```text
group_id
action label
locked route path
post_review_state
operator_reason_redacted
idempotency_key_hash
```

The UI must not submit an `action_operation` request body field.

The route remains authoritative for operation mapping:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

## Locked duplicate-click and idempotency behavior

The UI may disable action buttons while an action is pending.

Backend idempotency remains authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI must not introduce a new idempotency identity.

## Locked permission-aware behavior

Permission-aware button state remains advisory only.

Backend authorization remains authoritative.

Read-only permission must not authorize actions:

```text
duplicate_group:read
```

Action-specific permissions remain:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Bounded UI disabled reason:

```text
action_permission_missing
```

Bounded read-only message:

```text
Read-only permission does not authorize actions.
```

## Locked accessibility and usability hints

Stage 6.7 locks lightweight hints only:

```text
skip link to action controls
main and section aria-labelledby attributes
navigation aria-label
status role for bounded status messages
alert role for bounded error messages
table captions
fieldset and legend groups for action controls
aria-describedby for action form, action buttons, confirmation dialog, and submit button
aria-live on bounded action result
```

No frontend framework, asset pipeline, public UI, or external dependency was added.

## Locked action request allowlist

Allowed action request fields remain:

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
```

Forbidden action request material remains:

```text
action_operation override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Locked bounded action result

Allowed bounded action result fields remain:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
redaction_status
pre_review_state
post_review_state
review_state
action_event_inserted
```

Forbidden result material remains:

```text
unredacted operator reason
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
full article text
canonical payloads
unbounded diagnostics
```

## Locked tests

Stage 6.7 continues to rely on targeted UI route coverage:

```text
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

The targeted test verifies:

```text
list UI states
detail JSON route dependency
permission-aware action controls
confirmation modal
confirmed action POST flow
cancel path
bounded action result
detail refresh after action
accessibility and usability hints
existing JSON API invariants
no UI render side effects
```

## Public response-shape lock

Stage 6.7 UI polish must not change:

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

Public duplicate group review/action state fields remain absent.

## Canonical no-mutation lock

Stage 6.7 UI polish must not:

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

## Provider, scheduler, and materializer lock

Stage 6.7 UI polish must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction lock

UI implementation, tests, docs, review comments, logs, and tickets must not contain:

```text
raw actor identifier
raw request identifier
raw idempotency key
unredacted operator reason
raw provider payload
full article text
canonical payload
private transport material
SQL detail
provider secret
request header
cookie
unbounded diagnostic blob
stack trace
```

Allowed placeholders remain:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_OPERATOR_REASON
REDACTED_PROVIDER_PAYLOAD
```

## Future work gates

Before further UI changes, require a scoped PR that states:

```text
affected UI route
JSON API impact
action operation impact
public response-shape impact
canonical impact
provider/scheduler/materializer impact
redaction impact
test impact
```

Before public duplicate group exposure, require a separate public exposure design PR.

Before adding a frontend framework, asset pipeline, or external dependency, require a separate design PR.

## Close-out validation

This close-out PR is docs-only.

It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
