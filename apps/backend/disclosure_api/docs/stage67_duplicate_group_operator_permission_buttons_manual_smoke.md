# Stage 6.7 duplicate group operator permission-aware button manual smoke

This manual smoke checklist validates the Stage 6.7 duplicate group operator permission-aware button state implementation.

## Scope

Stage 6.7 PR D adds advisory permission-aware button states to the existing internal/admin duplicate group detail route:

```text
GET /admin/duplicate-groups/:group_id
```

The route path remains unchanged. The implementation may route that path to a dedicated thin HTML controller, but it must not add a new UI path, JSON API route, action operation, storage behavior, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_permission_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_permission_buttons_manual_smoke.md
```

The router change should keep the same path and only change the internal HTML controller target for:

```text
GET /admin/duplicate-groups/:group_id
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 99e9f00b37284e9c01aa80ba1a3da47f1230597c...HEAD
```

Expected output should be limited to the four files above.

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html list screen
GET /admin/duplicate-groups/:group_id returns 200 text/html detail screen with permission-aware action controls
GET /api/admin/duplicate-groups still returns the locked JSON list response
```

## Permission-aware control check

The detail screen should include:

```text
data-permission-aware = advisory-only
duplicate-group-action-permission-state
data-permission-state = unknown
Permission state pending operator input.
```

Each action button should include the required permission hint:

```text
Confirm duplicate group -> duplicate_group:confirm
Reject duplicate group -> duplicate_group:reject
Mark needs review -> duplicate_group:mark_review
Clear review state -> duplicate_group:clear_review_state
```

The UI should update button state from `actor_permissions`:

```text
hasPermission(permission)
hasAnyActionPermission()
updatePermissionButtonStates()
data-permission-state = enabled | disabled
data-disabled-reason = action_permission_missing
```

## Read-only state check

Read-only permission must not authorize actions.

The UI should show a bounded disabled reason for read-only-only permission:

```text
Read-only permission does not authorize actions.
```

Backend authorization remains authoritative. Client-side permission state is advisory only.

## Button state check

When an action-specific permission is present, the matching button may be enabled.

When an action-specific permission is absent, the matching button should be disabled with:

```text
data-disabled-reason = action_permission_missing
```

Pending state may also disable buttons, but must not change backend idempotency behavior.

## Existing confirmation guardrail

The confirmation modal should remain present:

```text
duplicate-group-action-confirmation-modal
Confirm operator action
Submit confirmed action
Cancel
```

Clicking a disabled button should not submit an action. Confirmed submission should still go only through the locked action routes.

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
adds a new UI path
adds a new JSON API route
adds public duplicate group fields
changes existing JSON API route behavior
adds new action operations
submits action_operation in request bodies
allows read-only permission to enable actions
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
