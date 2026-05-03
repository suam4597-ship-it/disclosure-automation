# Stage 6.0 duplicate group operator action no-op service manual smoke

This smoke checklist covers Stage 6.0 duplicate group operator action no-op service.

## Scope

The service composes the Stage 6.0 duplicate group operator action request contract and action audit contract to produce a bounded no-op preview result only.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage60_duplicate_group_operator_action_noop_service.ex
apps/backend/disclosure_api/test/stage60_duplicate_group_operator_action_noop_service_test.exs
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_action_noop_service_manual_smoke.md
```

## Prerequisites

```text
PR #137 merged: Stage 6.0 duplicate group operator actions/audit design locked
PR #138 merged: Stage 6.0 duplicate group operator action request contract locked
PR #139 merged: Stage 6.0 duplicate group operator action audit contract locked
```

Base for this PR:

```text
7e23cb9f2e5645da815c8fec4ce6cca0ab14341a
```

## No-op service smoke

Confirm the service:

```text
validates action request through Stage60DuplicateGroupOperatorActionContract
builds audit event through Stage60DuplicateGroupOperatorActionAuditContract
returns bounded no-op action preview
returns bounded no-op action_result
returns bounded audit_event
performs no runtime side effects
```

## Expected no-op flags

The service and action result must keep these values:

```text
no_op: true
fake_side_effects_only: true
action_attempt_recorded: true
audit_event_built: true
public_response_shape_mutation: false
public_api_duplicate_group_fields: false
public_feed_duplicate_group_fields: false
canonical_feed_mutation: false
provider_canonical_feed_item_creation: false
news_only_event_creation: false
official_event_merge: false
official_fact_override: false
official_citation_override: false
trigger_live_fetch: false
scheduler_enabled: false
network_access: forbidden
db_write: false
audit_write_performed: false
enqueue_performed: false
materializer_triggered: false
route_added: false
ui_added: false
action_endpoint_added: false
schema_migration: false
```

## Action smoke

Confirm supported operations produce preview results:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Confirm default post-review states are bounded:

```text
confirm_duplicate_group -> confirmed_by_operator
reject_duplicate_group -> rejected_by_operator
mark_duplicate_group_needs_review -> needs_review
clear_duplicate_group_review_state -> cleared
```

## Contract propagation smoke

Confirm the no-op service propagates action contract errors for:

```text
read permission used for action
missing action-specific permission
invalid operation
non-hash actor_id_hash
non-hash request_id_hash
non-hash idempotency_key_hash
raw actor/request/idempotency fields
unredacted operator reason
```

Confirm the no-op service propagates audit contract errors for:

```text
invalid result_status
invalid pre_review_state
invalid post_review_state
invalid redaction_status
```

## Audit context smoke

Allowed audit context keys:

```text
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

Unknown context keys must be rejected.

Raw actor/request/idempotency/operator reason fields must be rejected.

## Forbidden payload smoke

Confirm the no-op service rejects:

```text
raw provider bodies
request headers
response headers
provider credentials
provider secret values
full article text
canonical feed payloads
provider canonical creation payloads
canonical event payloads
raw body similarity payloads
full text similarity payloads
unbounded diagnostics
```

## No route/action/audit-write smoke

Confirm this PR does not add or modify:

```text
router
controllers
UI code
action endpoints
audit write code
schema modules
migrations
scheduler code
provider clients
live fetch code
materializer behavior
public feed/API behavior
canonical mutation behavior
```

## Suggested commands

```powershell
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
