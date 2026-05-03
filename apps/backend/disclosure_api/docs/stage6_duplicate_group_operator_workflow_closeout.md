# Stage 6 duplicate group operator workflow close-out

This document closes out the duplicate group operator workflow through Stage 6.4 after duplicate group materialization, operator read routes, operator action contracts, action state storage, action routes, review state read projections, admin read response metadata, and operator UI design guardrails were locked.

## Scope

The duplicate group operator workflow now supports an internal/backend path to:

```text
materialize bounded duplicate groups
read duplicate groups through internal/operator-only routes
record operator actions through locked action routes
persist bounded review state and action event metadata
read current review state and bounded latest action summaries
serialize bounded review metadata in admin read responses
design future operator UI and UI shell routes without implementation
```

This close-out PR is docs-only. It does not add runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, UI routes, frontend code, templates, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 8f8bb1ef598a05ca9973ec1e95aaf77ff7b95e31
base source: PR #157 Lock Stage 6.4 duplicate group operator UI design
status: docs-only overall workflow close-out
```

## Major lock evidence

```text
Stage 5.9 duplicate group workflow locked
PR #136 Lock Stage 5.9 duplicate group workflow
merge evidence: Stage 5.9 materialization/read route close-out
scope: duplicate group contract, storage, schema, materializer, internal read projection, admin read route

Stage 6.0 duplicate group operator actions locked
PR #142 Lock Stage 6.0 duplicate group operator actions
scope: operator action contract, audit contract, no-op service, authorization gate

Stage 6.1 duplicate group action state locked
PR #147 Lock Stage 6.1 duplicate group action state
scope: action state storage migration, schemas, transaction writer

Stage 6.2 duplicate group action routes locked
PR #150 Lock Stage 6.2 duplicate group action routes
scope: operator-only action routes backed by Stage 6.1 writer

Stage 6.3 duplicate group review state read projection locked
PR #154 Lock Stage 6.3 duplicate group review state read projection
scope: review_state_summary, show-only action_event_summary, admin read response serialization

Stage 6.4 duplicate group operator UI design locked
PR #157 Lock Stage 6.4 duplicate group operator UI design
merge commit: 8f8bb1ef598a05ca9973ec1e95aaf77ff7b95e31
scope: docs-only operator UI/experience and candidate UI shell route design
```

## Detailed implementation evidence

The workflow was built in small locked steps:

```text
PR #125 Design Stage 5.9 cross-source duplicate groups
PR #126 Add Stage 5.9 cross-source duplicate group contract
PR #127 Add Stage 5.9 duplicate group projection contract
PR #128 Add Stage 5.9 duplicate group noop service
PR #129 Design Stage 5.9 duplicate group storage schema
PR #130 Add Stage 5.9 duplicate group storage migration
PR #131 Add Stage 5.9 duplicate group schemas
PR #132 Add Stage 5.9 duplicate group internal materializer
PR #133 Design Stage 5.9 duplicate group operator review route
PR #134 Add Stage 5.9 duplicate group internal read projection
PR #135 Add Stage 5.9 duplicate group operator read route
PR #136 Lock Stage 5.9 duplicate group workflow

PR #137 Design Stage 6.0 duplicate group operator actions audit
PR #138 Add Stage 6.0 duplicate group operator action contract
PR #139 Add Stage 6.0 duplicate group operator action audit contract
PR #140 Add Stage 6.0 duplicate group operator action noop service
PR #141 Add Stage 6.0 duplicate group operator action authorization gate
PR #142 Lock Stage 6.0 duplicate group operator actions

PR #143 Design Stage 6.1 duplicate group action state storage
PR #144 Add Stage 6.1 duplicate group action state storage migration
PR #145 Add Stage 6.1 duplicate group action state schemas
PR #146 Add Stage 6.1 duplicate group action state writer
PR #147 Lock Stage 6.1 duplicate group action state

PR #148 Design Stage 6.2 duplicate group action routes
PR #149 Add Stage 6.2 duplicate group action routes
PR #150 Lock Stage 6.2 duplicate group action routes

PR #151 Design Stage 6.3 duplicate group review state read projection
PR #152 Add Stage 6.3 duplicate group review state read projection
PR #153 Add Stage 6.3 duplicate group admin read route response metadata
PR #154 Lock Stage 6.3 duplicate group review state read projection

PR #155 Design Stage 6.4 duplicate group operator UI experience
PR #156 Design Stage 6.4 duplicate group operator UI shell routes
PR #157 Lock Stage 6.4 duplicate group operator UI design
```

## Locked internal read routes

The workflow locks these internal/operator-only read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Locked read behavior:

```text
bounded internal duplicate group metadata only
bounded member metadata only
review_state_summary on list and show responses
action_event_summary on show responses only
list excludes action event history
missing review state renders bounded null metadata
read routes do not trigger materialization
read routes do not write action state
read routes do not call providers
read routes do not mutate canonical data
```

## Locked action routes

The workflow locks these internal/operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Locked route-to-operation mapping:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

The request body must not override the route-derived operation.

## Locked action writer path

Action routes must delegate persistence to:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
```

The writer remains responsible for:

```text
authorization gate validation
action contract validation
audit event validation
changeset validation
transactional event/state writes
action event idempotency
review state upsert
```

Route handlers and future UI shell routes must not write directly to:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

## Locked authorization model

The workflow locks action authorization around:

```text
authenticated actor context
operator or admin role
action-specific permission
actor_id_hash consistency
```

Action-specific permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Read-only permission must not authorize action routes:

```text
duplicate_group:read
```

Client-side or future UI authorization must never replace backend authorization.

## Locked action state storage

The workflow locks these internal tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Review state uniqueness:

```text
group_id
```

Action event idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Repeated action calls with the same identity must not duplicate action event rows.

New action/idempotency combinations may create new action event rows and update the single current review state row for the group.

## Locked review state summary

Internal/operator-only list and show responses may expose `review_state_summary`.

Allowed fields:

```text
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
```

Missing review state rows must be represented with bounded null metadata and must not trigger writes.

## Locked action event summary

Internal/operator-only show responses may expose `action_event_summary`.

Allowed fields:

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

The action event summary is locked to the latest five events.

List responses must not expose action event history.

## Locked UI design status

Stage 6.4 is design-only.

No UI is implemented by this workflow close-out.

Locked future UI constraints:

```text
future UI depends only on existing internal/operator-only JSON APIs
candidate shell routes are internal/admin candidates only
list UI excludes action event history
detail UI may use bounded show-only action_event_summary
action controls map exactly to locked action routes
request body cannot override route-derived action operation
backend authorization remains authoritative
shell routes must not directly query duplicate/action state tables
shell routes must not write action state
```

Candidate future shell routes remain unimplemented:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

## Locked forbidden material

The workflow must not store, return, render, log, or expose:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
SQL details
provider secrets
request headers
cookies
raw transport metadata
```

`operator_reason_redacted` remains excluded from action event summary route responses. Current-state reason text may be exposed only as bounded `review_reason_redacted` inside `review_state_summary`.

## Public response-shape lock

The workflow must preserve existing public response shapes:

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

Public duplicate group review/action state fields remain absent.

## Canonical no-mutation lock

Duplicate group operator workflow behavior remains advisory and internal.

Forbidden by default:

```text
canonical_feed_items mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
canonical fact override
news_overlay_attachments mutation
```

## Provider, scheduler, and materializer lock

Locked read/action/UI design behavior must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

The Stage 5.9 materializer remains the bounded internal materialization path and must not be triggered by read routes, action routes, or future UI shell routes.

## Regression suite to preserve

Future adjacent work should preserve these checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_authorization_gate_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_audit_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Future work gates

Before any future duplicate group UI implementation, require a separate implementation PR that states scope, route placement, authorization, response fields, idempotency, redaction, public response-shape impact, canonical policy, failure behavior, tests, and manual smoke checklist.

Before any future public response, scheduler, provider, materializer, canonical, or external integration work, require a separate design PR.

Before expanding duplicate group action operations, require a separate design PR covering authorization, audit event shape, storage, idempotency, route mapping, tests, and manual smoke.

## Close-out validation

This close-out PR is docs-only. It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
