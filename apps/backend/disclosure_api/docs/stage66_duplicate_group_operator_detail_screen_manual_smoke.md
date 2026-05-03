# Stage 6.6 duplicate group operator detail screen manual smoke

This manual smoke checklist validates the Stage 6.6 duplicate group operator detail screen implementation.

## Scope

Stage 6.6 PR D adds the internal/operator-only duplicate group detail screen behavior to the existing admin UI route:

```text
GET /admin/duplicate-groups/:group_id
```

The detail screen remains a browser surface that loads bounded detail data only from the locked internal JSON API:

```text
GET /api/admin/duplicate-groups/:group_id
```

This PR must not implement action controls, action submission, new API routes, new storage, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_detail_screen_manual_smoke.md
```

The router should remain unchanged from the Stage 6.6 shell-route PR unless a reviewer explicitly asks for route changes.

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 3dd64f2ca5d83e492b5677b3ce92a8de2b42d40f...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_detail_screen_manual_smoke.md
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

## Detail screen content check

The detail route should include:

```text
Duplicate Group Detail
duplicate-group-operator-detail-screen
duplicate-group-summary
duplicate-group-review-state
duplicate-group-members
duplicate-group-action-event-summary
duplicate-group-action-controls-placeholder
```

## API dependency check

The detail screen should load data only from:

```text
GET /api/admin/duplicate-groups/:group_id
```

The detail screen must not call action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Action controls are deferred to a later Stage 6.6 PR.

## Group summary field check

The detail screen may render bounded group summary fields:

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

It must not render raw provider payloads, canonical payloads, full article text, or unbounded diagnostics.

## Review state field check

The detail screen may render bounded review state fields:

```text
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
review_state_summary.reviewed_by_actor_id_hash
review_state_summary.redaction_status
```

It must not render raw actor identifiers, raw request identifiers, raw idempotency keys, or unredacted operator reasons.

## Member table check

The detail screen may render bounded member fields:

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

It must not render raw external IDs, provider payloads, full article text, or canonical payloads.

## Action event summary check

The detail screen may render `action_event_summary` only from the locked show response.

Allowed action event summary columns:

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

The action event summary must remain:

```text
show-response-only
latest-five-from-show-response
```

The detail screen must not request unbounded action history.

## Action control placeholder check

The detail screen should include only a deferred action control placeholder:

```text
data-action-controls = deferred
```

It must not include Confirm, Reject, Mark needs review, or Clear review state buttons in this PR.

## Existing JSON API invariants

The existing JSON route must remain available and unchanged:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
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

The detail screen controller must not call:

```text
Stage59DuplicateGroupInternalReadProjection
Stage61DuplicateGroupActionStateWriter
provider clients
scheduler code
materializers
canonical mutation code
```

The detail screen must not directly query or write:

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
calls action routes from the detail screen
requests unbounded action history
changes existing JSON API route behavior
queries duplicate group/action state tables from the UI controller
writes action state from UI routes
shows raw/private operator metadata
returns provider payloads/full text/canonical payloads
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
changes public feed/API response shapes
```
