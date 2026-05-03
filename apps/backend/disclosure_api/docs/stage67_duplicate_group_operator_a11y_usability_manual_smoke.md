# Stage 6.7 duplicate group operator accessibility and usability manual smoke

This manual smoke checklist validates the Stage 6.7 duplicate group operator accessibility and basic usability pass.

## Scope

Stage 6.7 PR E adds lightweight accessibility and usability hints to the existing internal/admin duplicate group detail UI.

This PR must not add new UI routes, JSON API routes, action operations, storage behavior, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_permission_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_a11y_usability_manual_smoke.md
```

The router should remain unchanged.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 81bed1fd957f72bc0fd1d569cadd50113295c04a...HEAD
```

Expected output should be limited to the three files above.

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html list screen
GET /admin/duplicate-groups/:group_id returns 200 text/html detail screen with accessibility hints
GET /api/admin/duplicate-groups still returns the locked JSON list response
```

## Accessibility hints check

The detail screen should include:

```text
skip link to #duplicate-group-action-controls
main aria-labelledby duplicate-group-detail-title
navigation aria-label
section aria-labelledby attributes
status role for bounded status messages
alert role for bounded error messages
table captions
fieldset and legend groups for action controls
aria-describedby for action form and action buttons
aria-describedby for confirmation dialog
aria-live on bounded action result
```

## Existing behavior preservation check

The detail screen must still include:

```text
data-detail-api-route = /api/admin/duplicate-groups/:group_id
loadDetail()
fetch(detailRoute, accept application/json)
openConfirmation(button)
submitAction(button)
fetch(button.getAttribute('data-action-route'), method POST)
body: JSON.stringify(actionPayload(button))
return loadDetail()
boundedActionResult(result)
confirmation submit handler
confirmation cancel handler
```

## Permission state check

Permission-aware behavior must remain advisory only:

```text
data-permission-aware = advisory-only
Read-only permission does not authorize actions.
Action permission missing.
Action permissions available. Backend authorization remains authoritative.
```

Backend authorization remains authoritative.

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
changes existing JSON API route behavior
adds new action operations
submits action_operation in request bodies
removes detail JSON loading
removes confirmation submit/cancel flow
removes action POST flow
removes detail refresh after action
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
