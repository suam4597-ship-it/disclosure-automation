# Stage 6.0 duplicate group operator actions lock close-out

This document locks Stage 6.0 duplicate group operator action and audit guardrails after the pure authorization gate was merged.

## Scope

Stage 6.0 introduced a design, pure action request contract, pure action audit contract, internal no-op preview service, and pure authorization gate for future duplicate group operator actions.

The stage remains no-op only. It does not add runtime action endpoints, audit writes, schema changes, UI, provider work, scheduler work, public response changes, materializer behavior, or canonical mutations.

## Lock evidence

```text
PR #137 Design Stage 6.0 duplicate group operator actions audit
merge commit: f4d456d6cc74e0e0b6e3a4cdf13912927361708d
scope: docs-only action/audit design, permission checklist, manual smoke

PR #138 Add Stage 6.0 duplicate group operator action contract
merge commit: 2dc8cce102e9f62509a7534c0f2f4699c8871332
scope: pure action request contract + targeted tests + manual smoke

PR #139 Add Stage 6.0 duplicate group operator action audit contract
merge commit: 7e23cb9f2e5645da815c8fec4ce6cca0ab14341a
scope: pure action audit event contract + targeted tests + manual smoke

PR #140 Add Stage 6.0 duplicate group operator action noop service
merge commit: e6999fd695374b48540c2887260445ab7bf29afa
scope: no-op preview service composing action/audit contracts + targeted tests + manual smoke

PR #141 Add Stage 6.0 duplicate group operator action authorization gate
merge commit: 335aa7813d821a3a1a9ba73930b173980aca4800
scope: pure authorization gate for no-op previews + targeted tests + manual smoke
```

## Locked action operations

Stage 6.0 locks this duplicate group operator action operation allowlist:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Unknown operations must remain rejected.

Read-only permission must not be accepted as an action operation.

## Locked permission model

Read permission remains separate from action permissions.

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

Locked permission rules:

```text
read permission cannot authorize actions
each operation requires its mapped action permission
action permission mismatch is rejected
authenticated actor context is required
operator or admin role is required
actor_id_hash is required
actor_id_hash must match action request actor_id_hash
```

## Locked action request contract

The action request contract accepts bounded, redacted request metadata only:

```text
group_id
action_operation
actor_permissions
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
redaction_status
```

The action request contract rejects:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason fields
unknown operations
read-only permission as action
missing action-specific permission
non-hash actor_id_hash
non-hash request_id_hash
non-hash idempotency_key_hash
raw provider payloads
transport metadata
full article text
canonical payloads
```

## Locked audit event contract

The audit contract accepts bounded, redacted audit event metadata only:

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

The audit contract must remain pure. It validates an event shape only and does not write audit rows.

## Locked no-op service behavior

The no-op service must:

```text
compose Stage60DuplicateGroupOperatorActionContract
compose Stage60DuplicateGroupOperatorActionAuditContract
return bounded preview only
return bounded action_result only
build bounded audit_event only
derive safe default post-review state by action operation
propagate action contract errors
propagate audit contract errors
reject unknown audit context keys
```

The no-op service must not:

```text
write DB rows
write audit rows
enqueue work
trigger duplicate group materialization
trigger live provider fetch
call provider clients
mutate canonical data
add routes
add action endpoints
add UI
```

## Locked authorization gate behavior

The authorization gate must:

```text
require authenticated actor context
require operator or admin role
require action-specific permission
reject read-only permission for actions
require hash-shaped actor_id_hash
require actor_id_hash to match action request actor_id_hash
reject unknown actor context keys
propagate action contract errors
propagate no-op service errors
return no-op preview only
```

The authorization gate must not:

```text
perform runtime authorization integration beyond pure validation
write audit rows
write DB rows
add action endpoints
add routes
add UI
mutate canonical data
trigger provider or scheduler work
```

## Locked no-op flags

Stage 6.0 action no-op preview and authorization gate behavior must keep side-effect flags false:

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

`network_access` must remain `forbidden`.

## Public response-shape lock

Stage 6.0 must preserve existing public response shapes:

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

Public duplicate group fields remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation lock

Stage 6.0 duplicate group operator actions remain non-canonical and advisory-only.

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

Stage 6.0 duplicate group operator actions must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
read provider credentials
store provider credentials
store provider transport metadata
materialize duplicate groups
materialize overlays
```

## Redaction lock

Stage 6.0 action request validation, audit event validation, no-op preview, authorization gate, tests, docs, review comments, logs, and manual-smoke output must not include non-redacted private provider or operator material.

Forbidden material:

```text
provider secret values
provider transport material
request header values
response header values
cookie values
raw provider response bodies
full article text
canonical feed payloads
provider canonical creation payloads
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
unbounded diagnostics
```

Allowed placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
```

## Regression suite to preserve

Future Stage 6.0 adjacent work should preserve these checks:

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

## Future work gates

Before any future duplicate group action endpoint, audit write, storage schema, UI, scheduler, provider, materializer, public response, or canonical behavior, require a separate design PR that states:

```text
scope and non-goals
authorization and permission model
audit write requirements
storage and idempotency policy
redaction policy
public response-shape impact
canonical no-mutation or explicit mutation design
failure isolation behavior
targeted tests
manual smoke checklist
```

## Close-out validation

This close-out PR is docs-only.

It must not change:

```text
runtime code
tests
fixtures
migrations
schema modules
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
