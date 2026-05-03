# Stage 6.6 duplicate group operator action controls manual smoke

This manual smoke checklist validates the Stage 6.6 duplicate group operator action controls implementation.

## Scope

Stage 6.6 PR E adds bounded operator action controls to the existing internal/admin duplicate group detail screen:

```text
GET /admin/duplicate-groups/:group_id
```

The action controls submit only to locked internal/operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

This PR must not add new action operations, new API routes, new storage, new read projection behavior, new action writer behavior, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_action_controls_manual_smoke.md
```

The router should remain unchanged from the Stage 6.6 shell-route PR unless a reviewer explicitly asks for route changes.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only dd8362ba0487ad70ad300980435425e71feb2019...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_action_controls_manual_smoke.md
```

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html list screen
GET /admin/duplicate-groups/:group_id returns 200 text/html detail screen with action controls
GET /api/admin/duplicate-groups still returns the locked JSON list response
```

## Action control content check

The detail route should include:

```text
duplicate-group-action-controls
data-action-controls = enabled
data-operation-override = forbidden
duplicate-group-action-form
duplicate-group-action-status
duplicate-group-action-result
```

Buttons should be present for:

```text
Confirm duplicate group
Reject duplicate group
Mark needs review
Clear review state
```

## Locked route mapping check

Each button must map exactly to one locked action route:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The route, not the request body, chooses the operation.

## Request body allowlist check

The action form may submit only bounded/redacted action request fields:

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

The action form must not submit:

```text
action_operation
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

## Operation override check

Search for route operation override fields in the detail action form.

Expected result:

```text
no name="action_operation"
no action_operation property in the action request payload
```

The page may still display bounded `action_event_summary.action_operation` values returned from the locked show response.

## Idempotency and pending-state check

The action controls should:

```text
send idempotency_key_hash
send request_id_hash
disable all action buttons while a request is pending
re-enable all action buttons after completion or failure
```

Backend idempotency remains authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

## Refresh check

After a successful action submission, the UI should refresh detail data by calling:

```text
GET /api/admin/duplicate-groups/:group_id
```

Refresh must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

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

The browser submits to the locked JSON action routes. The UI controller itself remains a thin HTML surface and must not directly query or write:

```text
source_duplicate_groups
source_duplicate_group_members
source_duplicate_group_action_events
source_duplicate_group_review_states
```

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
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Stop conditions

Stop and re-scope if the PR:

```text
adds new action routes
adds new action operations
submits action_operation in the request body
changes existing JSON API route behavior
queries duplicate group/action state tables from the UI controller
writes action state from UI routes directly
shows raw/private operator metadata
returns provider payloads/full text/canonical payloads
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
changes public feed/API response shapes
```
