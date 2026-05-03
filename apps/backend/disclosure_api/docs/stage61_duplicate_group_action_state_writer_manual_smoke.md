# Stage 6.1 duplicate group action state writer manual smoke

This smoke checklist covers the Stage 6.1 internal duplicate group action state writer.

## Scope

The writer records authorized duplicate group operator actions into internal review state and action event tables.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage61_duplicate_group_action_state_writer.ex
apps/backend/disclosure_api/test/stage61_duplicate_group_action_state_writer_test.exs
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_writer_manual_smoke.md
```

## Prerequisites

```text
PR #143 merged: Stage 6.1 storage design locked
PR #144 merged: Stage 6.1 storage migration locked
PR #145 merged: Stage 6.1 schemas locked
```

Base for this PR:

```text
5adb9f1e350f70154cbf2038546492397fc32f41
```

## Writer smoke

Confirm the writer:

```text
uses Stage60DuplicateGroupOperatorActionAuthorizationGate before writes
uses SourceDuplicateGroupActionEvent changeset
uses SourceDuplicateGroupReviewState changeset
uses Repo.transaction for event/state writes
inserts an idempotent action event
upserts the latest review state by group_id
returns bounded internal result metadata
```

## Idempotency smoke

Confirm repeated calls with the same identity do not duplicate action event rows:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm repeated calls with a new idempotency key insert a new action event and still keep one review state row per `group_id`.

## Authorization smoke

Confirm unauthorized action attempts write no rows:

```text
read-only duplicate_group:read permission
missing action-specific permission
unauthenticated actor context
actor hash mismatch
invalid actor hash
```

## Guardrail smoke

Confirm opt-ins are rejected before writes:

```text
public response shape mutation
public API duplicate group fields
public feed duplicate group fields
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official event merge
official fact override
official citation override
live fetch
scheduler work
network access
enqueue
materializer trigger
routes
UI
action endpoint
schema migration
```

## No endpoint smoke

Confirm this PR does not add or modify:

```text
router
controllers
UI code
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
API response behavior
feed response behavior
materializer behavior
canonical mutation behavior
```

## Redaction smoke

Confirm changed files and writer output do not include:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
provider secret values
provider transport material
request header values
response header values
cookie values
raw provider response bodies
full article text
canonical feed payloads
provider canonical creation payloads
unbounded diagnostics
```

## Suggested commands

```powershell
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
