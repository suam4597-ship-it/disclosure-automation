# Stage 6.0 duplicate group operator action audit contract manual smoke

This smoke checklist covers Stage 6.0 duplicate group operator action audit event contract.

## Scope

The contract validates future duplicate group operator action audit events without adding routes, action endpoints, audit writes, schema changes, provider work, scheduler work, materializer behavior, public response changes, or canonical mutations.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage60_duplicate_group_operator_action_audit_contract.ex
apps/backend/disclosure_api/test/stage60_duplicate_group_operator_action_audit_contract_test.exs
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_action_audit_contract_manual_smoke.md
```

## Prerequisites

```text
PR #137 merged: Stage 6.0 duplicate group operator actions/audit design locked
PR #138 merged: Stage 6.0 duplicate group operator action request contract locked
```

Base for this PR:

```text
2dc8cce102e9f62509a7534c0f2f4699c8871332
```

## Contract smoke

Confirm the audit contract is pure and has no side effects.

It should validate only bounded redacted audit metadata:

```text
group_id
action_operation
required_permission
actor_id_hash
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

The contract must keep these flags false:

```text
public_response_shape_mutation
public_api_duplicate_group_fields
public_feed_duplicate_group_fields
canonical_feed_mutation
provider_canonical_feed_item_creation
news_only_event_creation
official_event_merge
official_fact_override
official_citation_override
trigger_live_fetch
scheduler_enabled
audit_write_performed
materializer_triggered
route_added
ui_added
action_endpoint_added
schema_migration
```

## Operation smoke

Allowed operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Unknown operations must be rejected.

Read-only permission used as an operation must be rejected.

## Permission smoke

Read permission:

```text
duplicate_group:read
```

Action permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Confirm read permission cannot authorize an action audit event.

Confirm each operation requires its mapped action-specific permission.

## Audit state smoke

Allowed result statuses:

```text
pending
accepted
denied
rejected
failed
completed
skipped
```

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Allowed redaction statuses:

```text
passed
failed
blocked
unknown
```

Invalid states must be rejected.

## Redaction smoke

Confirm the contract rejects raw fields:

```text
actor_id
actor_email
actor_name
request_id
idempotency_key
operator_reason
operator_note
```

Confirm the contract accepts only hash-shaped fields:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
```

Confirm the contract accepts only redacted operator reason field:

```text
operator_reason_redacted
```

## Forbidden payload smoke

Confirm the contract rejects:

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
