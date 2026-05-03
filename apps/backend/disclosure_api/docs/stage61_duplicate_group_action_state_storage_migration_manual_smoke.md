# Stage 6.1 duplicate group action state storage migration manual smoke

This smoke checklist covers the Stage 6.1 internal duplicate group operator action state and event storage migration.

## Scope

This PR adds internal storage tables only.

Expected changed files:

```text
apps/backend/disclosure_api/priv/repo/migrations/20260503123000_create_stage61_duplicate_group_action_tables.exs
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_storage_migration_manual_smoke.md
```

## Prerequisites

```text
PR #143 merged: Stage 6.1 duplicate group action state storage design locked
```

Base for this PR:

```text
f83487ea2d855d36bbed37a8ed265c2c3845e7e2
```

## Migration smoke

Confirm the migration creates only internal duplicate group operator action storage tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Confirm the migration does not backfill rows.

Confirm the migration does not add schema modules or runtime write code.

## Review state table smoke

Confirm `source_duplicate_group_review_states` includes bounded internal fields only:

```text
id
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

Confirm uniqueness:

```text
group_id
```

Confirm indexes are bounded and internal only:

```text
group_id unique
review_state
last_action_operation
reviewed_by_actor_id_hash
redaction_status
```

## Action event table smoke

Confirm `source_duplicate_group_action_events` includes bounded internal fields only:

```text
id
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

Confirm idempotency uniqueness:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm indexes are bounded and internal only:

```text
group_id
action_operation
actor_id_hash
request_id_hash
result_status
redaction_status
```

## No runtime behavior smoke

Confirm this PR does not add or modify:

```text
runtime writer code
schema modules
changesets
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

## Public response smoke

Confirm this migration does not change public response shapes:

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

Confirm this migration does not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Redaction smoke

Confirm changed files do not include non-redacted provider secret values, raw header values, cookie values, raw operator identifiers, raw request identifiers, raw idempotency keys, raw provider bodies, full article text, canonical payloads, or unbounded diagnostics.

## Suggested commands

```powershell
$env:MIX_ENV='test'; mix.bat ecto.migrate
$env:MIX_ENV='test'; mix.bat ecto.rollback --step 1
$env:MIX_ENV='test'; mix.bat ecto.migrate
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
