# Stage 6.6 duplicate group operator UI lock close-out

This document locks the Stage 6.6 internal duplicate group operator UI implementation after the implementation design, shell route, list screen, detail screen, action controls, and integration tests were merged.

## Scope

Stage 6.6 implements the internal/admin duplicate group operator UI for the locked duplicate group operator workflow.

Stage 6.6 remains internal/operator-only, advisory-only, non-canonical, bounded, and redacted.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Lock evidence

```text
PR #161 Design Stage 6.6 duplicate group operator UI implementation
scope: docs-only implementation design, guardrails, manual smoke

PR #162 Add Stage 6.6 duplicate group operator UI shell routes
scope: minimal internal/admin HTML shell routes and shell tests

PR #163 Add Stage 6.6 duplicate group operator list screen
scope: bounded list screen using locked JSON list API only

PR #164 Add Stage 6.6 duplicate group operator detail screen
scope: bounded detail screen using locked JSON show API only

PR #165 Add Stage 6.6 duplicate group operator action controls
scope: bounded action controls mapped to locked JSON action routes

PR #166 Add Stage 6.6 duplicate group operator UI integration tests
scope: test/docs-only integration coverage and manual smoke
```

Latest baseline after PR #166:

```text
merge commit: 7adfdc39250e7206dfb0a15ce7ede54ee3df9526
```

## Locked UI routes

Stage 6.6 locks these internal/admin HTML UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

These routes are not public routes and are not JSON API routes.

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

The UI depends only on locked internal/operator-only JSON APIs.

List data source:

```text
GET /api/admin/duplicate-groups
```

Detail data source:

```text
GET /api/admin/duplicate-groups/:group_id
```

Action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The UI must not create alternate read/action/write APIs.

## Locked list screen behavior

The locked list route is:

```text
GET /admin/duplicate-groups
```

The list screen loads data only from:

```text
GET /api/admin/duplicate-groups
```

Locked bounded list filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Locked bounded list fields:

```text
group_id
confidence
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
member_count
source_keys
redaction_status
```

The list screen links group IDs to:

```text
/admin/duplicate-groups/:group_id
```

The list screen must not render:

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

The list screen must not call action routes.

## Locked detail screen behavior

The locked detail route is:

```text
GET /admin/duplicate-groups/:group_id
```

The detail screen loads data only from:

```text
GET /api/admin/duplicate-groups/:group_id
```

Locked detail sections:

```text
group summary
review_state_summary
members table
latest action_event_summary
action controls
```

Locked bounded group summary fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
```

Locked bounded review state fields:

```text
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
review_state_summary.reviewed_by_actor_id_hash
review_state_summary.redaction_status
```

Locked bounded member fields:

```text
member_id
member_kind
source_key
provider
external_id_hash
official_event_id
overlay_id
confidence
match_reasons
redaction_status
```

## Locked action event summary behavior

The detail screen may render `action_event_summary` only from the locked show response.

Locked action event summary fields:

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

The action event summary remains:

```text
show-response-only
latest-five-from-show-response
```

The UI must not request unbounded action history.

The UI must not render:

```text
operator_reason_redacted action history
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Locked action controls

Stage 6.6 locks action controls on:

```text
GET /admin/duplicate-groups/:group_id
```

Each button maps exactly to one locked action route:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The route chooses the action operation.

The UI must not submit an `action_operation` request body field.

Locked route-derived mapping remains:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

## Locked action request allowlist

The UI may submit only bounded/redacted action request fields:

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

Forbidden action request material:

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

## Locked idempotency behavior

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI may disable duplicate clicks while a request is pending.

Backend idempotency remains authoritative.

Same intended action retries should reuse the same idempotency key hash.

New intended actions should use a new idempotency key hash.

## Locked refresh behavior

After an action completes, the UI refreshes detail data from:

```text
GET /api/admin/duplicate-groups/:group_id
```

Refresh must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Locked authorization behavior

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

Client-side controls are convenience UI only and must not replace backend authorization.

## Locked UI controller boundaries

The UI controller is a thin HTML surface.

It must not call:

```text
Stage59DuplicateGroupInternalReadProjection
Stage61DuplicateGroupActionStateWriter
provider clients
scheduler code
materializers
canonical mutation code
```

It must not directly query or write:

```text
source_duplicate_groups
source_duplicate_group_members
source_duplicate_group_action_events
source_duplicate_group_review_states
```

The browser uses locked JSON APIs for reads and action submissions.

## Locked tests

Stage 6.6 locks targeted UI route tests and integration tests.

Locked route test:

```text
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Locked integration test:

```text
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_integration_test.exs
```

The tests cover:

```text
list screen locked JSON dependency
detail screen locked JSON dependency
action controls locked route mapping
no action_operation request body override
show-response-only latest action summary
read-only action rejection
rendering UI pages does not create review/action rows
public/canonical/provider/scheduler/materializer guardrails
```

## Public response-shape lock

Stage 6.6 UI work must not change:

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

Stage 6.6 UI work must not:

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

Stage 6.6 UI work must not:

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

UI implementation, tests, fixtures, docs, review comments, logs, and tickets must not contain:

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
```

Allowed placeholders:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_OPERATOR_REASON
REDACTED_PROVIDER_PAYLOAD
```

## Future work gates

Before changing Stage 6.6 UI behavior, require a scoped PR that states affected routes, public response-shape impact, canonical impact, provider/scheduler/materializer impact, action route/action operation impact, redaction impact, and tests.

Before public duplicate group exposure, require a separate public exposure design PR.

Before UI polish beyond this locked Phase 1 screen set, require a separate Stage 6.7 or Phase 2 design/implementation sequence.

## Close-out validation

This close-out PR is docs-only.

It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
