# Source Health Poll Audit Runtime Contract

This document defines the future bounded audit runtime contract for the source health poll gated stream.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d2fa5b7b131fbb54a2ad6c23f1d02ca52a6ce40a
base source: PR #258 Add source health poll rate-limit runtime close-out
stream: source health poll audit runtime contract
status: docs-only contract
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

## Goal

Define the audit runtime contract before adding poll audit writes.

Audit should provide bounded observability for poll outcomes without changing HTTP response shapes or exposing raw/private/canonical material.

## Non-goals

This contract does not implement or approve:

```text
audit storage migration
audit runtime writes
audit read UI
audit event IDs in HTTP responses
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
poll UI
runtime metric emission
```

## Fixed route operation

Poll audit route operation must be fixed by server code:

```text
source_health:poll
```

Request body must not be able to override route operation.

Forbidden override fields:

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

## Audit outcome statuses

Approved result statuses:

```text
accepted
reused
missing_key_denied
rate_limited
forbidden
not_found
invalid_request
failed
```

Approved idempotency statuses:

```text
accepted
reused
missing_key_denied
none
```

Approved rate-limit statuses:

```text
allowed
rate_limited_global
rate_limited_source
rate_limited_actor
none
```

## Outcome mapping

Future audit runtime should map poll outcomes as follows:

```text
accepted poll -> result_status=accepted, idempotency_status=accepted, rate_limit_status=allowed
reused poll -> result_status=reused, idempotency_status=reused, rate_limit_status=allowed
missing key -> result_status=missing_key_denied, idempotency_status=missing_key_denied, rate_limit_status=none
rate limited -> result_status=rate_limited, idempotency_status=none, rate_limit_status=<bounded rate-limit status>
forbidden -> result_status=forbidden, idempotency_status=none, rate_limit_status=none
unknown source -> result_status=not_found, idempotency_status=none, rate_limit_status=none
invalid request -> result_status=invalid_request, idempotency_status=none, rate_limit_status=none
unexpected bounded failure -> result_status=failed, idempotency_status=none, rate_limit_status=none
```

## Recommended audit storage table

Recommended table:

```text
source_health_poll_audit_events
```

Recommended bounded columns:

```text
id
source_key
route_operation
result_status
idempotency_status
rate_limit_status
actor_id_hash
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
occurred_at
metadata
inserted_at
updated_at
```

The audit table may optionally include bounded references to idempotency/rate-limit rows:

```text
idempotency_key_id
rate_limit_key_id
```

These references must not be exposed in HTTP responses.

## Forbidden audit storage fields

Audit storage must not include:

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
```

## HTTP response lock

Adding audit runtime must not alter poll HTTP response shape.

HTTP responses must not include:

```text
audit_event
audit_event_id
audit_primary_key
idempotency_key_id
rate_limit_key_id
raw actor/request/idempotency identifiers
```

Current bounded responses should remain bounded:

```text
404 not_found
403 forbidden
409 missing_idempotency_key
429 rate_limited
202 reused
202 accepted or existing poll result for accepted path
```

## Audit write timing

Recommended audit write timing:

```text
not_found -> after source lookup fails
forbidden -> after authorization fails
missing_key_denied -> after idempotency key validation fails
reused -> after active idempotency record is found
rate_limited -> after rate-limit check fails
accepted -> after accepted idempotency record is created and before or after existing poll execution according to runtime decision
failed -> only for bounded unexpected failures
```

If audit write fails, the poll response should remain bounded and should not expose audit write errors.

## Body override handling

Audit runtime must ignore request body attempts to override:

```text
route_operation
result_status
idempotency_status
rate_limit_status
audit_event_id
```

Server-derived values must win.

## Provider/materializer/canonical boundary

Audit runtime does not approve provider, materializer, or canonical behavior.

Still not approved by audit:

```text
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
canonical_mutation
```

## Test plan for future implementation

Recommended future test file:

```text
apps/backend/disclosure_api/test/source_health_poll_audit_runtime_contract_test.exs
```

Recommended tests:

```text
accepted poll writes bounded audit event
reused poll writes bounded audit event
missing idempotency key writes bounded audit event
rate-limited poll writes bounded audit event
forbidden poll writes bounded audit event if the authorization plug is wired to audit
unknown-source poll writes bounded audit event if the source lookup path is wired to audit
audit route_operation cannot be overridden by request body
audit result/idempotency/rate-limit statuses are server-derived
audit write failure does not expose raw diagnostics in HTTP response
HTTP responses do not include audit event IDs
raw/private/canonical material is absent from audit records
```

First implementation may start with storage contract tests before runtime audit writes.

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_contract_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before audit runtime work:

```text
112 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future audit work:

```text
exposes audit event IDs in HTTP responses
allows request body to override route_operation or result statuses
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reasons
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
changes public API/feed shapes
adds poll UI before backend gates are locked
adds duplicate controller modules
calls provider clients inline without a design/test gate
triggers materializers inline without a design/test gate
mutates canonical data without a design/test gate
```

## Validation for this contract PR

This contract PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_audit_runtime_contract.md
```

No Codex test command is required for this docs-only contract PR.
