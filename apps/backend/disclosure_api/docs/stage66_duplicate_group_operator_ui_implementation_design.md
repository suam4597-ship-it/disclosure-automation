# Stage 6.6 duplicate group operator UI implementation design

This document defines a docs-only implementation design for the next internal duplicate group operator UI work after the Stage 6.5 operator runbook was locked.

Stage 6.6 PR A is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 686a3d3be22b32c7f0bdd9ebe7b3b2bbdf6ccbd7
base source: PR #160 Lock duplicate group operator runbook
stage: Stage 6.6 PR A duplicate group operator UI implementation design
status: docs-only
```

Locked upstream inputs:

```text
Stage 5.9 read routes: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
Stage 6.2 action routes: POST /api/admin/duplicate-groups/:group_id/confirm, reject, mark-review, clear-review-state
Stage 6.3 read metadata: bounded review_state_summary and show-only latest-five action_event_summary
Stage 6.4 UI design: internal/admin shell routes only, design-only
Stage 6.5 runbook: operator procedure, idempotency, redaction, escalation, and forbidden behavior
```

## Purpose

Stage 6.6 PR A converts the previous UI experience and shell-route designs into an implementation plan without implementing the UI yet.

The goal is to make the next implementation PR small and reviewable:

```text
PR 162: minimal internal/admin UI shell route implementation
PR 163: operator duplicate group list screen
PR 164: operator duplicate group detail screen
PR 165: operator action controls
PR 166: operator UI integration tests and smoke checks
PR 167: Stage 6.6 operator UI lock close-out
```

## Current repo observations

The current router exposes only the JSON API scope for duplicate groups:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The current Phoenix web module exposes a JSON controller macro only:

```text
use Phoenix.Controller, formats: [:json]
```

The current static path list is empty:

```text
static_paths, do: []
```

Therefore the first implementation PR should not assume an existing browser pipeline, HTML controller macro, template stack, LiveView stack, asset pipeline, or static bundle path.

## Design decision

Stage 6.6 should implement a thin internal/admin UI surface in small PRs, starting with a minimal shell route.

The UI implementation must depend on the locked JSON APIs for duplicate group data and actions. It must not add a second read projection path, direct table access from UI routes, new action semantics, new storage, provider work, scheduler work, materializer behavior, public response-shape changes, or canonical mutations.

## Non-goals

This design does not authorize or implement:

```text
public duplicate group UI
public duplicate group API fields
public feed response changes
new duplicate group read APIs
new duplicate group action APIs
new action operations
new migrations
new schemas
new read projection behavior
new writer behavior
provider live fetch
provider clients
scheduler enqueueing
materializer triggering
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
unbounded action history
raw/private identifier display
unredacted operator reason display
```

## Implementation target

Future implementation should target the existing Phoenix backend app under:

```text
apps/backend/disclosure_api
```

The first implementation PR should add only an internal/admin HTML shell surface for:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

The implementation PR must keep existing `/api/admin/duplicate-groups` JSON routes unchanged.

## Candidate file plan for PR 162

PR 162 should be minimal and shell-only. Candidate files are:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_shell_route_manual_smoke.md
```

If the implementation introduces a reusable HTML controller macro, template module, or static asset path, it must keep the change scoped and document why the simpler controller-shell option was insufficient.

Candidate optional files, only if justified:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/admin_duplicate_group_ui_html.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_html/*.html.heex
apps/backend/disclosure_api/priv/static/admin_duplicate_group_operator_ui.js
```

PR 162 should not add list data rendering, detail data rendering, action controls, action forms, or frontend data mutation logic beyond static shell configuration.

## Shell rendering approach

Because the current app is JSON-only, PR 162 should prefer the smallest viable shell approach:

```text
1. add an internal/admin route namespace outside /api
2. add a dedicated UI shell controller distinct from AdminDuplicateGroupController
3. return a minimal text/html response
4. embed only static, non-private API route configuration
5. include a generic guardrail/redaction notice
```

A future PR may move the shell to templates or static assets if that remains scoped and tested.

A future implementation must not reuse `AdminDuplicateGroupController` for HTML. The existing controller is the locked JSON API surface and should remain focused on JSON read/action responses.

## Candidate UI routes

Future UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

These routes must be internal/admin-only, non-public, and distinct from API routes.

Forbidden route namespaces:

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

## API dependency model

The UI must use only the locked internal/operator-only JSON APIs.

List data:

```text
GET /api/admin/duplicate-groups
```

Detail data:

```text
GET /api/admin/duplicate-groups/:group_id
```

Actions:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The UI must not query duplicate group tables, review state tables, or action event tables directly.

## PR 162 shell requirements

The shell route implementation should verify:

```text
/admin/duplicate-groups returns an internal shell
/admin/duplicate-groups/:group_id returns an internal shell
shell response is text/html
shell identifies the locked JSON API routes the UI may call
shell contains no raw actor/request/idempotency identifiers
shell contains no provider payloads, full article text, or canonical payloads
shell does not call Stage59DuplicateGroupInternalReadProjection
shell does not call Stage61DuplicateGroupActionStateWriter
shell does not call provider clients
shell does not enqueue scheduler work
shell does not trigger materializers
shell does not mutate canonical data
existing /api/admin/duplicate-groups JSON behavior remains unchanged
```

## PR 163 list screen requirements

The list screen should fetch list data from:

```text
GET /api/admin/duplicate-groups
```

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Allowed list display fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
```

Forbidden list display fields:

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

## PR 164 detail screen requirements

The detail screen should fetch detail data from:

```text
GET /api/admin/duplicate-groups/:group_id
```

Allowed detail sections:

```text
group summary
member summary table
review_state_summary
latest-five action_event_summary
action control placeholder area
redaction/guardrail notice
```

The detail screen may display `action_event_summary` only from the locked show response. It must preserve the latest-five limit and must not request or render unbounded action history.

## PR 165 action control requirements

Action controls must map exactly to locked routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

The UI must not send an `action_operation` field that can override the route-derived operation.

Allowed action request fields remain:

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
failure_code
created_at
```

Forbidden action request material remains:

```text
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

## Authorization design

Future UI routes must be internal/operator-only.

Minimum authorization requirements:

```text
authenticated actor
operator or admin role for shell access
duplicate_group:read permission for list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

Read-only permission must not authorize actions:

```text
duplicate_group:read
```

Action controls require action-specific permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Client-side disabled states are advisory only. Backend authorization remains the source of truth.

## Idempotency and duplicate-click design

The locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI should disable duplicate clicks while an action is pending, but backend idempotency remains authoritative.

A retry of the same intended action should reuse the same idempotency key hash.

A new intended action should use a new idempotency key hash.

## Refresh design

After a successful action, the UI should refresh the detail state by calling:

```text
GET /api/admin/duplicate-groups/:group_id
```

Optional list refresh may call:

```text
GET /api/admin/duplicate-groups
```

Refresh must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Failure rendering design

Allowed failure categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Forbidden failure rendering material:

```text
SQL details
raw request bodies
private actor context
provider payloads
full text
canonical payloads
headers
cookies
secrets
unbounded diagnostics
```

## Public response-shape guardrails

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

Public duplicate group review/action state fields must remain absent.

## Canonical no-mutation guardrails

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

## Provider, scheduler, and materializer guardrails

Stage 6.6 UI work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## PR 166 test plan

Targeted tests should cover:

```text
shell route access and content-type
list screen fetch contract
list screen excludes action_event_summary
detail screen includes bounded action_event_summary
Confirm button calls confirm route only
Reject button calls reject route only
Mark review button calls mark-review route only
Clear review state button calls clear-review-state route only
request body cannot override route-derived operation
read-only users cannot submit actions
raw/private identifiers are not rendered
public feed/API responses are unchanged
canonical/provider/scheduler/materializer side effects remain absent
```

## Stop conditions

Do not merge Stage 6.6 implementation PRs if they:

```text
add public duplicate group fields
change public response shapes
change existing JSON API route behavior
change action endpoint behavior
change action write behavior
bypass Stage 6.1 writer
bypass Stage 6.0 authorization gate
query duplicate group/action state tables directly from UI routes
write action state from UI routes
allow request-body override of route-derived action operation
show raw actor/request/idempotency identifiers
show unredacted operator reasons
show raw provider payloads or full article text
show canonical payloads
return unbounded diagnostics
mutate canonical data
trigger provider/scheduler/live-fetch work
change materializer behavior
```
