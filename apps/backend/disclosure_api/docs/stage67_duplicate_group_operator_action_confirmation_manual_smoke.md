# Stage 6.7 duplicate group operator action confirmation manual smoke

This manual smoke checklist validates the Stage 6.7 duplicate group operator action confirmation modal and duplicate-click prevention implementation.

## Scope

Stage 6.7 PR C adds a bounded confirmation step before operator action submission on the existing internal/admin duplicate group detail screen:

```text
GET /admin/duplicate-groups/:group_id
```

The confirmation step must not add new UI routes, new JSON API routes, new action operations, new storage, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_action_confirmation_manual_smoke.md
```

The router should remain unchanged.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 6b007f966fa4d18104d0ac9891430b736144dbaf...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_action_confirmation_manual_smoke.md
```

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html list screen
GET /admin/duplicate-groups/:group_id returns 200 text/html detail screen with confirmation modal
GET /api/admin/duplicate-groups still returns the locked JSON list response
```

## Confirmation modal check

The detail screen should include:

```text
duplicate-group-action-confirmation-modal
role = dialog
aria-modal = true
data-confirmation-state = closed
Confirm operator action
This confirmation is bounded and redacted.
```

The confirmation modal may show only bounded fields:

```text
group_id
action_label
locked_route_path
post_review_state
operator_reason_redacted
idempotency_key_hash
```

The modal must not show:

```text
action_operation request-body override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
stack traces
```

## Confirmation flow check

Action button click should open confirmation instead of directly submitting:

```text
openConfirmation(button)
pendingActionButton = button
data-confirmation-state = open
Confirm operator action before submitting.
```

Confirmed submission should occur only after:

```text
Submit confirmed action
```

Cancel should close the modal without submitting.

## Duplicate-click prevention check

The UI should prevent duplicate submissions while a request is pending:

```text
actionPending = true while submitting
all action buttons disabled while pending
confirmation submit button disabled while pending
if actionPending return before opening another confirmation
submit only if pendingActionButton exists and actionPending is false
```

Backend idempotency remains authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

## Idempotency/request hash check

The confirmation flow should ensure these hash fields exist before submission:

```text
request_id_hash
idempotency_key_hash
```

The generated values should remain hash-shaped placeholders:

```text
sha256:request-...
sha256:idempotency-...
```

The UI must not generate or submit raw request identifiers or raw idempotency keys.

## Action route mapping check

Action buttons must still map exactly to locked routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The route chooses the operation.

The UI must not submit an `action_operation` request body field.

## Bounded action result check

The action result rendering should still use a bounded result projection only.

Allowed result fields:

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

The bounded result must not show:

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

## Existing JSON API invariants

The existing JSON routes must remain available and unchanged:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Expected locked invariant fields on the list route:

```text
mode = stage59_internal_duplicate_group_list_projection
route_added = true
ui_added = false
action_endpoint_added = false
materializer_triggered = false
public_response_shape_mutation = false
public_api_duplicate_group_fields = false
public_feed_duplicate_group_fields = false
canonical_feed_mutation = false
trigger_live_fetch = false
scheduler_enabled = false
network_access = forbidden
```

## Side-effect verification

The UI controller must not call:

```text
Stage59DuplicateGroupInternalReadProjection
Stage61DuplicateGroupActionStateWriter
provider clients
scheduler code
materializers
canonical mutation code
```

The UI controller must not directly query or write:

```text
source_duplicate_groups
source_duplicate_group_members
source_duplicate_group_action_events
source_duplicate_group_review_states
```

The browser uses locked JSON APIs for reads and action submissions.

## Public response-shape guardrail

This PR must not change:

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

Public duplicate group review/action state fields must remain absent.

## Canonical no-mutation guardrail

This PR must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer guardrail

This PR must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Stop conditions

Stop and re-scope if the PR:

```text
adds public duplicate group fields
changes existing JSON API route behavior
adds new action operations
submits action_operation in request bodies
submits directly from action button click without confirmation
allows duplicate submissions while pending
requests unbounded action history
queries duplicate group/action state tables from the UI controller
writes action state from UI routes directly
shows raw actor/request/idempotency identifiers
shows unredacted operator reasons
shows raw provider payloads or full article text
shows canonical payloads
returns unbounded diagnostics or stack traces
mutates canonical data
triggers provider/scheduler/live-fetch work
changes materializer behavior
changes public feed/API response shapes
```
