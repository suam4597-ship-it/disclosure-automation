# Stage 6.6 duplicate group operator list screen manual smoke

This manual smoke checklist validates the Stage 6.6 duplicate group operator list screen implementation.

## Scope

Stage 6.6 PR C adds the internal/operator-only duplicate group list screen behavior to the existing admin UI route:

```text
GET /admin/duplicate-groups
```

The list screen remains a browser shell that loads bounded list data only from the locked internal JSON API:

```text
GET /api/admin/duplicate-groups
```

This PR must not implement detail data rendering, action controls, action submission, new API routes, new storage, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_list_screen_manual_smoke.md
```

The router should remain unchanged from the Stage 6.6 shell-route PR unless a reviewer explicitly asks for route changes.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 25a899a2c07a6742543f1261a9b2afe6788e2050...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_list_screen_manual_smoke.md
```

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html
GET /admin/duplicate-groups/:group_id still returns 200 text/html detail shell
GET /api/admin/duplicate-groups still returns the locked JSON response
```

## List screen content check

The list route should include:

```text
Duplicate Groups
operator-only, advisory-only, non-canonical, bounded, and redacted
duplicate-group-operator-list-screen
duplicate-group-list-filters
duplicate-group-list-table
```

## Filter check

The list screen should expose only bounded list filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

The list screen must not expose unbounded diagnostics or arbitrary query-builder fields.

## Table column check

The list table should expose bounded list columns only:

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

The list screen must not show:

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

## API dependency check

The list screen should load data only from:

```text
GET /api/admin/duplicate-groups
```

The list screen may link each `group_id` to:

```text
/admin/duplicate-groups/:group_id
```

The list screen must not call action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Action controls are deferred to a later Stage 6.6 PR.

## Detail shell guardrail

The detail route remains a shell only in this PR:

```text
GET /admin/duplicate-groups/:group_id
```

It may still display locked detail/action API route configuration, but it must not fetch or render detail data yet.

## Existing JSON API invariants

The existing JSON route must remain available and unchanged:

```text
GET /api/admin/duplicate-groups
```

Expected locked invariant fields:

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

The list screen controller must not call:

```text
Stage59DuplicateGroupInternalReadProjection
Stage61DuplicateGroupActionStateWriter
provider clients
scheduler code
materializers
canonical mutation code
```

The list screen must not directly query or write:

```text
source_duplicate_groups
source_duplicate_group_members
source_duplicate_group_action_events
source_duplicate_group_review_states
```

The browser fetches the locked JSON API route; the UI controller itself remains a thin HTML surface.

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
adds action controls
calls action routes from the list screen
renders action_event_summary on the list screen
changes existing JSON API route behavior
queries duplicate group/action state tables from the UI controller
writes action state from UI routes
shows raw/private operator metadata
returns provider payloads/full text/canonical payloads
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
changes public feed/API response shapes
```
