# Source Health Poll Audit Runtime Write Flow Design

This document designs the future runtime write flow for source health poll audit events after poll audit storage has been locked.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 64cd44c0c118f9786975fe674d487318c3fd5863
base source: PR #262 Add source health poll audit storage close-out
stream: source health poll audit runtime write flow design
status: docs-only design
```

## Existing locked prerequisites

Poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Poll authorization:

```text
source_health:poll required
source_health:read is not enough
source_health:recheck is not enough
unknown source remains bounded 404
```

Poll idempotency runtime:

```text
missing/empty idempotency_key_hash -> bounded 409
first source_key + idempotency_key_hash -> accepted idempotency record
repeat source_key + idempotency_key_hash -> bounded reused response without poll execution
```

Poll rate-limit runtime:

```text
global/source_key/actor_id_hash checks
bounded 429 for rate-limited poll
reused/missing-key/forbidden/unknown-source paths do not increment counters
```

Poll audit storage:

```text
source_health_poll_audit_events
```

## Goal

Define where and how future runtime audit writes should occur without changing poll HTTP response shapes or exposing audit identifiers.

## Non-goals

This design does not implement or approve:

```text
audit runtime writes
audit read UI
audit IDs in HTTP responses
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
poll UI
runtime metric emission
```

## Fixed audit route operation

Every audit event must use the server-derived route operation:

```text
source_health:poll
```

The request body must never override this value.

Forbidden body override fields:

```text
operation
action_operation
route_operation
action
queue
worker
payload
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

## Runtime write timing

Future implementation should write audit events at these bounded decision points:

```text
not_found -> after source lookup fails
forbidden -> after authorization fails
missing_key_denied -> after idempotency key validation fails
reused -> after active idempotency record is found
rate_limited -> after rate-limit check fails
accepted -> after accepted idempotency record is created and before existing poll execution, or after existing poll execution if implementation wants to capture poll execution result
failed -> only for bounded unexpected failures
```

Recommended first implementation timing:

```text
not_found -> write best-effort audit
forbidden -> write best-effort audit
missing_key_denied -> write best-effort audit
reused -> write best-effort audit
rate_limited -> write best-effort audit
accepted -> write best-effort audit immediately after accepted idempotency record creation and before existing poll execution
```

Rationale:

```text
accepted audit records the gated operator action, not provider/materializer/canonical effects
provider/materializer/canonical effects remain separate gates
best-effort audit failures should not expose raw diagnostics
```

## Outcome mapping

Runtime outcome mapping should be:

```text
accepted -> result_status=accepted, idempotency_status=accepted, rate_limit_status=allowed
reused -> result_status=reused, idempotency_status=reused, rate_limit_status=allowed
missing_key_denied -> result_status=missing_key_denied, idempotency_status=missing_key_denied, rate_limit_status=none
rate_limited_global -> result_status=rate_limited, idempotency_status=none, rate_limit_status=rate_limited_global
rate_limited_source -> result_status=rate_limited, idempotency_status=none, rate_limit_status=rate_limited_source
rate_limited_actor -> result_status=rate_limited, idempotency_status=none, rate_limit_status=rate_limited_actor
forbidden -> result_status=forbidden, idempotency_status=none, rate_limit_status=none
not_found -> result_status=not_found, idempotency_status=none, rate_limit_status=none
invalid_request -> result_status=invalid_request, idempotency_status=none, rate_limit_status=none
failed -> result_status=failed, idempotency_status=none, rate_limit_status=none
```

## Bounded audit row values

Runtime may write only bounded fields:

```text
source_key
route_operation
result_status
idempotency_status
rate_limit_status
actor_id_hash
request_id_hash
idempotency_key_hash
idempotency_key_id
rate_limit_key_id
reason_redacted
redaction_status
occurred_at
metadata
```

Recommended first implementation:

```text
idempotency_key_id=nil unless source_health_poll_idempotency_keys id is already available
rate_limit_key_id=nil unless source_health_poll_rate_limits id is already available
metadata={}
```

## Forbidden audit row values

Runtime must not write:

```text
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
headers
cookies
tokens
provider_credentials
raw_provider_payload
full_article_text
raw_transport_response
sql_details
stack_trace
canonical_payload
private_actor_context
unbounded_diagnostics
audit_event_id
```

## HTTP response lock

Audit write implementation must not add audit identifiers to HTTP responses.

Forbidden HTTP response fields:

```text
audit_event
audit_event_id
audit_primary_key
idempotency_key_id
rate_limit_key_id
```

Existing bounded responses must remain bounded:

```text
404 not_found
403 forbidden
409 missing_idempotency_key
429 rate_limited
202 reused
202 accepted or existing poll result for accepted path
```

## Audit write failure behavior

Audit writes should be best-effort.

If audit write fails:

```text
HTTP response should remain the original bounded poll response
raw DB errors must not be returned
stack traces must not be returned
SQL details must not be returned
audit failure may be swallowed or logged only through a separate bounded logging contract
```

Recommended first implementation:

```text
rescue audit write failure and continue with bounded response
```

## Where to wire audit writes

Possible runtime locations:

```text
DisclosureAutomationWeb.SourceHealthPollAuthorization for forbidden/not_found authorization gate outcomes
DisclosureAutomation.SourceHealthPollRuntime for missing_key_denied/reused/rate_limited/accepted outcomes
DisclosureAutomationWeb.AdminSourcePollController only for final bounded HTTP rendering, not for deriving audit values
```

Recommended first implementation:

```text
add a server-side audit helper under DisclosureAutomation.SourceHealthPollRuntime or a dedicated DisclosureAutomation.SourceHealthPollAudit module
call helper from authorization plug and poll runtime helper
keep controller thin
```

## Future helper API

Recommended helper API:

```text
record_source_health_poll_audit(source_key, attrs, result_status, idempotency_status, rate_limit_status)
```

Expected behavior:

```text
stringify attrs keys
copy only bounded hash/redacted fields
force route_operation=source_health:poll
force server-derived status fields
best-effort insert into source_health_poll_audit_events
return :ok even if insert fails
```

## Body override prevention

Even if request body includes these fields, server-derived values must win:

```text
route_operation
result_status
idempotency_status
rate_limit_status
audit_event_id
idempotency_key_id
rate_limit_key_id
```

## Test plan for future implementation

Recommended future test file:

```text
apps/backend/disclosure_api/test/source_health_poll_audit_runtime_test.exs
```

Recommended tests:

```text
accepted poll writes bounded audit event
reused poll writes bounded audit event
missing idempotency key writes bounded audit event
rate-limited poll writes bounded audit event
forbidden poll writes bounded audit event
unknown-source poll writes bounded audit event
body override cannot alter route_operation/result/idempotency/rate-limit statuses
HTTP responses do not include audit IDs
audit write failure does not expose raw diagnostics
raw/private/canonical material is absent from audit rows
```

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before audit runtime write work:

```text
124 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future audit runtime work:

```text
exposes audit event IDs in HTTP responses
allows request body to override route_operation or result statuses
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reasons
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
returns audit write failures to the caller
changes public API/feed shapes
adds poll UI before backend gates are locked
adds duplicate controller modules
calls provider clients inline without a design/test gate
triggers materializers inline without a design/test gate
mutates canonical data without a design/test gate
```

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_audit_runtime_write_flow_design.md
```

No Codex test command is required for this docs-only design PR.
