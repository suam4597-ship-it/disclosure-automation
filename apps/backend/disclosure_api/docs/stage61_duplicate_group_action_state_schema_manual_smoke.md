# Stage 6.1 duplicate group action state schema manual smoke

This smoke checklist covers the Stage 6.1 duplicate group operator action review state and action event schemas.

## Scope

This PR adds schema modules and changeset tests only.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group_review_state.ex
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group_action_event.ex
apps/backend/disclosure_api/test/stage61_duplicate_group_action_state_schema_test.exs
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_schema_manual_smoke.md
```

## Prerequisites

```text
PR #143 merged: Stage 6.1 duplicate group action state storage design locked
PR #144 merged: Stage 6.1 duplicate group action state storage migration locked
```

Base for this PR:

```text
05a063e9546b701e865368b07f4ede8c7fbf1987
```

## Review state schema smoke

Confirm `SourceDuplicateGroupReviewState` maps only:

```text
source_duplicate_group_review_states
```

Allowed fields:

```text
group_id
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
inserted_at
updated_at
```

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Allowed action operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Allowed redaction statuses:

```text
passed
failed
blocked
unknown
```

Confirm the changeset rejects invalid states, invalid operations, non-hash identifiers, raw/private fields, and secret-like values.

## Action event schema smoke

Confirm `SourceDuplicateGroupActionEvent` maps only:

```text
source_duplicate_group_action_events
```

Allowed fields:

```text
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

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

Confirm action operation maps to required permission:

```text
confirm_duplicate_group -> duplicate_group:confirm
reject_duplicate_group -> duplicate_group:reject
mark_duplicate_group_needs_review -> duplicate_group:mark_review
clear_duplicate_group_review_state -> duplicate_group:clear_review_state
```

Confirm the changeset rejects mismatched permissions, invalid statuses, invalid review states, non-hash identifiers, raw/private fields, and secret-like values.

## Redaction smoke

Confirm both schemas reject forbidden fields:

```text
actor_id
actor_email
actor_name
request_id
idempotency_key
operator_reason
operator_note
request headers
response headers
provider credentials
raw provider bodies
full article text
canonical feed payloads
provider canonical creation payloads
canonical event payloads
raw similarity payloads
unbounded diagnostics
```

## No runtime behavior smoke

Confirm this PR does not add or modify:

```text
runtime writer code
routes
controllers
UI code
action endpoints
audit write services
scheduler code
provider clients
live fetch code
materializer behavior
public feed/API behavior
canonical mutation behavior
```

## Suggested commands

```powershell
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
