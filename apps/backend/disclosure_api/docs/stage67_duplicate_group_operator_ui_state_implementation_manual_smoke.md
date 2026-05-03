# Stage 6.7 duplicate group operator UI state implementation manual smoke

This manual smoke checklist validates the Stage 6.7 duplicate group operator UI loading, empty, and bounded error state implementation.

## Scope

Stage 6.7 PR B implements bounded UI state handling on the existing internal/admin duplicate group operator UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

This PR must not add new UI routes, new JSON API routes, new action operations, new storage, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_state_implementation_manual_smoke.md
```

The router should remain unchanged.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 26c5319e03c0f5c1fda7aa12200ad67acbeef891...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_state_implementation_manual_smoke.md
```

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html list screen
GET /admin/duplicate-groups/:group_id returns 200 text/html detail screen
GET /api/admin/duplicate-groups still returns the locked JSON list response
```

## List state check

The list screen should include bounded state elements:

```text
duplicate-group-list-status
duplicate-group-list-loading-state
duplicate-group-list-empty-state
duplicate-group-list-error-state
```

Allowed list state text:

```text
Ready to load duplicate groups.
Loading duplicate groups.
Loaded duplicate groups.
No duplicate groups found.
Unable to load duplicate groups.
```

The list error state should use:

```text
data-error-category = unable_to_load_duplicate_groups
```

## Detail state check

The detail screen should include bounded state elements:

```text
duplicate-group-detail-status
duplicate-group-detail-loading-state
duplicate-group-detail-error-state
duplicate-group-review-state-empty
duplicate-group-members-empty
duplicate-group-action-event-empty
```

Allowed detail state text:

```text
Ready to load duplicate group detail.
Loading duplicate group detail.
Loaded duplicate group detail.
Unable to load duplicate group detail.
No review state recorded yet.
No members found.
No latest actions found.
```

The detail error state should use:

```text
data-error-category = unable_to_load_duplicate_group_detail
```

## Action state check

The action controls should include bounded action state elements:

```text
duplicate-group-action-status
duplicate-group-action-loading-state
duplicate-group-action-error-state
duplicate-group-action-success-state
```

Allowed action state text:

```text
Ready for an operator action.
Submitting action.
Action submitted. Refreshing detail.
Action submitted and detail refreshed.
Unable to submit action.
```

The action error state should use:

```text
data-error-category = unable_to_submit_action
```

## Bounded action result check

The action result rendering should use a bounded result projection only.

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
