# Stage 6.6 duplicate group operator UI integration tests manual smoke

This manual smoke checklist validates the Stage 6.6 duplicate group operator UI integration test pass.

## Scope

Stage 6.6 PR F adds integration coverage for the internal/admin duplicate group operator UI after the shell, list screen, detail screen, and action controls were implemented.

This PR is test/docs-only. It must not add or modify:

```text
runtime code
router
controllers
templates
frontend behavior
migrations
schema modules
read projection behavior
action writer behavior
action endpoint behavior
provider clients
scheduler code
live fetch code
materializer code
public API controllers
public feed controllers
canonical mutation behavior
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_integration_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_integration_tests_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 9f0db619b10adf8a3b2f8c3c3d564f94c8205f4b...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_integration_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_integration_tests_manual_smoke.md
```

## Test command

Run the new integration test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_integration_test.exs
```

Recommended adjacent checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
```

## UI contract coverage

The integration test should verify that the list screen:

```text
uses data-list-api-route=/api/admin/duplicate-groups
fetches only the locked list JSON route
links detail pages through /admin/duplicate-groups/:group_id
excludes action_event_summary from the list screen
excludes action routes from the list screen
```

The integration test should verify that the detail screen:

```text
uses data-detail-api-route=/api/admin/duplicate-groups/:group_id
renders show-response-only action_event_summary
keeps latest-five-from-show-response summary metadata
renders enabled action controls
marks operation override as forbidden
```

## Action route flow coverage

The integration test should verify that action controls align with locked action routes by submitting through the existing JSON action route:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
```

Expected result:

```text
action_operation = confirm_duplicate_group
required_permission = duplicate_group:confirm
review_state = confirmed_by_operator
authorized = true
public_response_shape_mutation = false
canonical_feed_mutation = false
trigger_live_fetch = false
scheduler_enabled = false
materializer_triggered = false
```

## Refresh projection coverage

After action submission, the integration test should verify that the locked show route reflects the updated review state:

```text
GET /api/admin/duplicate-groups/:group_id
```

Expected refreshed fields:

```text
review_state_summary.review_state = confirmed_by_operator
review_state_summary.last_action_operation = confirm_duplicate_group
review_state_summary.last_action_request_id_hash = sha256:ui-request-001
review_state_summary.last_action_idempotency_key_hash = sha256:ui-idempotency-001
review_state_summary.reviewed_by_actor_id_hash = sha256:operator-001
```

Expected latest action summary fields:

```text
action_operation = confirm_duplicate_group
required_permission = duplicate_group:confirm
actor_id_hash = sha256:operator-001
request_id_hash = sha256:ui-request-001
idempotency_key_hash = sha256:ui-idempotency-001
```

The action event summary must not expose:

```text
operator_reason_redacted
raw_actor_id
raw_request_id
raw_idempotency_key
canonical_payload
```

## Route-derived operation coverage

The integration test should verify that an `action_operation` field in the body cannot override the route-derived operation.

Expected behavior:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
body action_operation = reject_duplicate_group
response action_operation = confirm_duplicate_group
response required_permission = duplicate_group:confirm
```

## Read-only rejection coverage

The integration test should verify that read-only permission cannot execute actions.

Expected behavior:

```text
actor_permissions = [duplicate_group:read]
POST /api/admin/duplicate-groups/:group_id/confirm returns 403
no source_duplicate_group_action_events rows are written
no source_duplicate_group_review_states rows are written
```

## Render side-effect coverage

The integration test should verify that rendering the UI pages does not create review/action state rows:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Expected state after rendering:

```text
source_duplicate_group_action_events count = 0
source_duplicate_group_review_states count = 0
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
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Stop conditions

Stop and re-scope if the PR:

```text
changes runtime code
changes existing JSON API route behavior
changes UI controller behavior
changes router behavior
adds new action routes
adds new action operations
submits action_operation in the UI request body
queries duplicate group/action state tables from the UI controller
writes action state from UI routes directly
shows raw/private operator metadata
returns provider payloads/full text/canonical payloads
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
changes public feed/API response shapes
```
