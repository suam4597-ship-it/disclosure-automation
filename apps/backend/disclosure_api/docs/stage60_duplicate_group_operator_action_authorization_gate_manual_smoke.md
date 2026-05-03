# Stage 6.0 duplicate group operator action authorization gate manual smoke

This smoke checklist covers Stage 6.0 duplicate group operator action authorization gate.

## Scope

The gate validates actor context before allowing a no-op preview of future duplicate group operator actions.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage60_duplicate_group_operator_action_authorization_gate.ex
apps/backend/disclosure_api/test/stage60_duplicate_group_operator_action_authorization_gate_test.exs
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_action_authorization_gate_manual_smoke.md
```

## Prerequisites

```text
PR #137 merged: Stage 6.0 duplicate group operator actions/audit design locked
PR #138 merged: Stage 6.0 duplicate group operator action request contract locked
PR #139 merged: Stage 6.0 duplicate group operator action audit contract locked
PR #140 merged: Stage 6.0 duplicate group operator action no-op service locked
```

Base for this PR:

```text
e6999fd695374b48540c2887260445ab7bf29afa
```

## Authorization smoke

Confirm the gate requires:

```text
authenticated actor context
operator or admin role
action-specific permission
actor_id_hash matching the action request actor_id_hash
```

Confirm the gate rejects:

```text
unauthenticated actor context
viewer-only actor context
missing action permission
read-only duplicate_group:read permission for action requests
actor hash mismatch
non-hash actor context
unknown actor context keys
```

## No-op preview smoke

Confirm the gate calls the Stage 6.0 no-op service only after authorization checks pass.

Confirm the authorized response returns:

```text
authorized: true
authorization_result: allowed_noop_preview
preview.no_op: true
preview.audit_event_built: true
preview.audit_write_performed: false
preview.db_write: false
preview.action_endpoint_added: false
```

## Side-effect smoke

Confirm the gate keeps these values false:

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
db_write
audit_write_performed
enqueue_performed
materializer_triggered
route_added
ui_added
action_endpoint_added
schema_migration
```

## Actor context smoke

Allowed actor context keys:

```text
authenticated
roles
permissions
actor_id_hash
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

Unknown context keys must be rejected.

## Redaction smoke

Confirm raw actor, request, idempotency, and operator reason fields are rejected:

```text
actor_id
actor_email
actor_name
request_id
idempotency_key
operator_reason
operator_note
```

Confirm forbidden provider/canonical fields are rejected:

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

## No route/action endpoint smoke

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
