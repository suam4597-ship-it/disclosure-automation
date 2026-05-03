# Stage 6.2 duplicate group action route lock close-out

This document locks Stage 6.2 duplicate group operator action route behavior after the route implementation was merged.

## Scope

Stage 6.2 introduced operator-only duplicate group action routes backed by the Stage 6.1 internal action state writer.

The routes remain internal/admin only. They do not add UI, public duplicate group fields, scheduler work, provider clients, live fetch behavior, materializer behavior changes, or canonical mutations.

## Lock evidence

```text
PR #148 Design Stage 6.2 duplicate group action routes
merge commit: 9ad4191b42f32c1031c128009306b9b338459007
scope: docs-only action route design, route guardrails, manual smoke

PR #149 Add Stage 6.2 duplicate group action routes
merge commit: 6fbfe9f9ec8896fb779b9c469a95aa4f29630454
scope: router/controller implementation, targeted route tests, manual smoke
```

## Locked action routes

Stage 6.2 locks these operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Existing read routes remain separate:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

## Locked route-to-operation mapping

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

The request body must not override the route-derived operation.

## Locked writer integration

Action route handlers must delegate persistence to:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
```

Route handlers must not write directly to:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
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

## Locked request fields

Allowed action request fields:

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

Forbidden request material includes raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, and unbounded diagnostics.

## Locked response behavior

Success responses must be bounded internal metadata only.

Allowed response fields:

```text
mode
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
redaction_status
pre_review_state
post_review_state
action_event_id
action_event_inserted
review_state_id
review_state
authorized
authorization_result
```

Failure responses must be bounded and must not expose raw request bodies, private actor context, SQL details, provider payloads, full text, canonical payloads, or unbounded diagnostics.

## Locked idempotency behavior

Locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Repeated route calls with the same identity must not duplicate action event rows.

New action route/idempotency combinations may create new action event rows.

Review state must remain one row per `group_id`.

## Locked permission behavior

Action routes must require action-specific permissions:

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

Unauthorized or invalid attempts must write no rows.

## Public response-shape lock

Stage 6.2 must preserve existing public response shapes:

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

Public duplicate group action state fields remain absent.

## Canonical no-mutation lock

Stage 6.2 action routes are advisory and internal.

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

## Provider and scheduler lock

Stage 6.2 action routes must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Redaction lock

Stage 6.2 routes, controllers, tests, docs, review comments, logs, and manual-smoke output must remain redacted and bounded.

Forbidden material includes raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, and unbounded diagnostics.

Allowed placeholder examples:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
```

## Regression suite to preserve

Future Stage 6.2 adjacent work should preserve these checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_authorization_gate_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_audit_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
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

Before any future duplicate group UI, public response, scheduler, provider, materializer, or canonical work, require a separate design PR that states scope, authorization, storage, idempotency, redaction, public response-shape impact, canonical policy, failure behavior, tests, and manual smoke checklist.

## Close-out validation

This close-out PR is docs-only. It must not change runtime code, tests, fixtures, migrations, schema modules, router, controllers, UI code, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
