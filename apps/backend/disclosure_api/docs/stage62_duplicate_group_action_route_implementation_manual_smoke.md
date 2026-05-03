# Stage 6.2 duplicate group action route implementation manual smoke

This smoke checklist covers the Stage 6.2 operator-only duplicate group action route implementation.

## Scope

This PR adds operator-only action routes backed by the Stage 6.1 internal action state writer.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_controller.ex
apps/backend/disclosure_api/test/stage62_duplicate_group_action_route_test.exs
apps/backend/disclosure_api/docs/stage62_duplicate_group_action_route_implementation_manual_smoke.md
```

## Prerequisites

```text
PR #148 merged: Stage 6.2 duplicate group action route design locked
```

Base for this PR:

```text
9ad4191b42f32c1031c128009306b9b338459007
```

## Route smoke

Confirm only these action routes are added:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm existing read routes remain unchanged:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

## Route-to-operation smoke

Confirm route handlers map to locked operations:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

Confirm request body cannot override route-derived operation.

## Writer integration smoke

Confirm action handlers call:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
```

Confirm controller does not write directly to:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

## Success response smoke

Confirm success responses are bounded and include:

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

Confirm guardrail flags remain false for public response shape, canonical mutation, provider work, scheduler work, enqueue, materializer, and UI.

## Idempotency smoke

Confirm repeated requests with the same identity do not duplicate rows:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm a new idempotency key inserts a new action event while keeping one review state row per group.

## Failure smoke

Confirm read-only permission returns a bounded 403 and writes no rows.

Confirm invalid bounded payload returns a bounded 400 and writes no rows.

Confirm failure responses do not expose raw request body, private actor context, SQL details, provider payloads, full text, canonical payloads, or unbounded diagnostics.

## Public response smoke

Confirm this PR does not change public response shapes:

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

## Canonical no-mutation smoke

Confirm action routes do not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider and scheduler smoke

Confirm action routes do not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Redaction smoke

Confirm changed files and route responses do not include raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Suggested commands

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
