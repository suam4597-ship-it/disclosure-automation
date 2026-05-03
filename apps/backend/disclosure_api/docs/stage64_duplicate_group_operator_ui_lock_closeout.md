# Stage 6.4 duplicate group operator UI design lock close-out

This document locks Stage 6.4 duplicate group operator UI design behavior after the operator UI/experience design and UI shell route design were merged.

## Scope

Stage 6.4 defines future internal/operator-only UI and UI shell route expectations for duplicate group review.

Stage 6.4 is currently design-only. It does not add UI implementation, frontend code, templates, router changes, controllers, UI routes, action endpoint changes, public response changes, scheduler work, provider clients, live fetch behavior, materializer behavior changes, or canonical mutations.

## Lock evidence

```text
PR #155 Design Stage 6.4 duplicate group operator UI experience
merge commit: fedfde71e92b61e423020486f7c406bde8295a66
scope: docs-only operator UI/experience design, guardrails, manual smoke

PR #156 Design Stage 6.4 duplicate group operator UI shell routes
merge commit: 57e5b9ab5315c5f577a872ad9e2f8fddbe338a48
scope: docs-only internal/admin UI shell route design, guardrails, manual smoke
```

## Locked design-only status

Stage 6.4 remains design-only.

Locked absence of implementation:

```text
no frontend code
no backend runtime code
no tests
no fixtures
no migrations
no schema modules
no router changes
no controllers
no templates
no UI routes
no action endpoint changes
no scheduler code
no provider clients
no live fetch code
no feed/controller behavior changes
no public API behavior changes
no public feed behavior changes
no materializer behavior changes
no canonical mutation behavior changes
```

## Locked future UI dependency model

Any future duplicate group operator UI must depend only on the existing internal/operator-only JSON APIs.

Read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Future UI work must not create alternate read/action/write APIs without a separate design and targeted implementation validation.

## Locked candidate shell routes

Future implementation may consider only these internal/admin HTML shell route candidates:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

These routes are candidates only. Stage 6.4 does not implement them.

Future shell routes must remain distinct from JSON APIs and must not replace, alias, or mutate the locked API routes.

## Locked forbidden route namespaces

Future duplicate group UI/shell work must not introduce duplicate group UI under public or side-effect namespaces:

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

## Locked list UI behavior

Future list UI behavior must remain bounded.

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Future list UI may display compact current review metadata but must not fetch or display action event history.

Allowed compact review metadata:

```text
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
review_state_summary.redaction_status
```

## Locked detail UI behavior

Future detail UI behavior may display bounded data from the locked show API.

Allowed sections:

```text
group summary
member summary table
review_state_summary
action_event_summary
action controls
redaction/guardrail notice
```

The detail UI may display `action_event_summary` because Stage 6.3 locks it for show responses only.

The UI must keep `action_event_summary` bounded and show-only, preserving the latest-five summary limit.

## Locked review state display fields

Future UI may display only these `review_state_summary` fields:

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

Missing review state must be rendered as a neutral state without creating or backfilling review state rows.

## Locked action event display fields

Future detail UI may display only these `action_event_summary` fields:

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

The UI must not display `operator_reason_redacted` in action event history unless a separate design explicitly changes the locked response contract.

## Locked action control mapping

Future action controls must map exactly to locked action routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Request body fields must not override route-derived action operation.

Read-only permission must not enable action controls:

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

## Locked action request allowlist

Future UI action submissions may include only bounded, already-redacted metadata accepted by locked action routes.

Allowed request fields:

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

Forbidden request material:

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

## Locked idempotency behavior

Locked idempotency identity remains:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

A future UI may disable duplicate clicks, but backend idempotency remains authoritative.

Retrying the same intended action after a transient failure should reuse the same idempotency key hash.

## Locked authorization behavior

Future UI/shell access must be internal/operator-only.

Minimum requirements:

```text
authenticated actor
operator or admin role for shell access
read permission for viewing list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

Future UI work must not bypass:

```text
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage61DuplicateGroupActionStateWriter
```

Client-side authorization must never replace backend authorization.

## Locked shell responsibility boundaries

Allowed future shell responsibilities:

```text
serve an internal operator-only page shell
load initial static configuration that contains no private identifiers
identify existing API routes the UI may call
show a generic redaction/guardrail notice
fail closed for unauthenticated or non-operator users
```

Forbidden shell responsibilities:

```text
query duplicate group tables directly
query action state tables directly
write action events
write review states
materialize duplicate groups
trigger provider live fetch
call provider clients
enqueue scheduler work
mutate canonical data
change public API/feed responses
embed raw actor identifiers
embed raw request identifiers
embed raw idempotency keys
embed provider payloads
embed canonical payloads
embed unbounded diagnostics
```

## Locked refresh behavior

After a successful action, future UI should refresh detail data by calling:

```text
GET /api/admin/duplicate-groups/:group_id
```

Optional list refresh may call:

```text
GET /api/admin/duplicate-groups
```

Refresh behavior must not trigger provider live fetch, scheduler work, duplicate group materialization, overlay materialization, canonical mutation, or public feed updates.

## Locked failure rendering behavior

Future UI failure rendering must remain bounded.

Allowed categories:

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

## Public response-shape lock

Stage 6.4 must preserve existing public response shapes:

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

Stage 6.4 UI/shell design remains advisory and internal.

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

Stage 6.4 UI/shell work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Redaction lock

Stage 6.4 UI/shell design docs, future implementation, tests, review comments, logs, and manual-smoke output must remain redacted and bounded.

Forbidden material includes raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, and unbounded diagnostics.

Allowed placeholder examples:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
```

## Regression suite to preserve

Future Stage 6.4 implementation work should preserve these checks:

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

Before any future public response, scheduler, provider, materializer, or canonical work, require a separate design PR.

## Close-out validation

This close-out PR is docs-only. It must not change frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router, controllers, templates, UI routes, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
