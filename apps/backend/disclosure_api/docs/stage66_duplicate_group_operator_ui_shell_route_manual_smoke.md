# Stage 6.6 duplicate group operator UI shell route manual smoke

This manual smoke checklist validates the Stage 6.6 minimal internal/admin duplicate group operator UI shell route implementation.

## Scope

Stage 6.6 PR B adds only a minimal internal/admin HTML shell route for future duplicate group operator UI work.

Expected implementation files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_shell_route_manual_smoke.md
```

This PR must not add or modify:

```text
migrations
schema modules
read projections
action writers
action endpoints
provider clients
scheduler code
live fetch code
materializer code
public API controllers
public feed controllers
canonical mutation behavior
frontend build tooling
unbounded action history behavior
```

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base source: PR #161 Design Stage 6.6 duplicate group operator UI implementation
scope: minimal shell route implementation
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 26b77314b345d1f2177586eb089ddd6c5241aae1...HEAD
```

Expected output should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_shell_route_manual_smoke.md
```

## Route smoke

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage66_duplicate_group_operator_ui_shell_route_test.exs
```

Expected behavior:

```text
GET /admin/duplicate-groups returns 200 text/html
GET /admin/duplicate-groups/:group_id returns 200 text/html
GET /api/admin/duplicate-groups still returns the locked JSON response
```

## Shell content check

The list shell should include:

```text
Duplicate Group Operator UI
operator-only duplicate group review
advisory-only, non-canonical, bounded, and redacted
/api/admin/duplicate-groups
/api/admin/duplicate-groups/:group_id
/api/admin/duplicate-groups/:group_id/confirm
/api/admin/duplicate-groups/:group_id/reject
/api/admin/duplicate-groups/:group_id/mark-review
/api/admin/duplicate-groups/:group_id/clear-review-state
```

The detail shell should include the encoded group-specific locked API routes.

## Non-goal verification

Verify the shell does not render or submit:

```text
action_operation override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Side-effect verification

The shell route test checks that visiting the detail shell does not create rows in:

```text
source_duplicate_groups
source_duplicate_group_members
source_duplicate_group_action_events
source_duplicate_group_review_states
```

The shell controller must not call:

```text
Stage59DuplicateGroupInternalReadProjection
Stage61DuplicateGroupActionStateWriter
provider clients
scheduler code
materializers
canonical mutation code
```

## Existing JSON API invariants

The existing JSON route must remain available:

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
changes existing JSON API route behavior
changes action endpoint behavior
changes action writer behavior
queries duplicate group/action state tables from the shell controller
writes action state from shell routes
allows request-body override of route-derived operation
shows raw/private operator metadata
returns provider payloads/full text/canonical payloads
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
changes public feed/API response shapes
```
