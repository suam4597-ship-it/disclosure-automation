# Source Health Poll Audit Storage Close-out

This document closes out the source health poll audit storage step.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 79e9935cbd21af4d8f331837fc9ea515ad72271c
base source: PR #261 Add source health poll audit storage tests
stream: source health poll audit storage close-out
status: docs-only
```

## Scope closed by PR #261

PR #261 added storage structure and DB-structure tests for future poll audit events.

Closed storage surface:

```text
source_health_poll_audit_events
```

Locked properties:

```text
bounded audit columns only
route_operation index
result_status index
idempotency_status index
rate_limit_status index
occurred_at index
idempotency_key_id index
rate_limit_key_id index
accepted bounded audit row insert
reused bounded audit row insert
rate-limited bounded audit row insert
missing-key bounded audit row insert
forbidden bounded audit row insert
not-found bounded audit row insert
raw/private/canonical columns absent
migration rollback/re-migrate cycle validated
```

## Explicit non-goals

PR #261 and this close-out do not implement:

```text
poll audit runtime writes
poll audit read UI
HTTP response audit IDs
route/controller changes
poll behavior changes
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
UI behavior changes
monitoring/dashboard/alert changes
```

## Poll audit table lock

Table:

```text
source_health_poll_audit_events
```

Required bounded columns:

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
idempotency_key_id
rate_limit_key_id
reason_redacted
redaction_status
occurred_at
metadata
inserted_at
updated_at
```

Required indexes:

```text
sh_poll_audit_source_key_idx
sh_poll_audit_route_operation_idx
sh_poll_audit_result_status_idx
sh_poll_audit_idem_status_idx
sh_poll_audit_rate_status_idx
sh_poll_audit_occurred_at_idx
sh_poll_audit_idem_key_id_idx
sh_poll_audit_rate_key_id_idx
```

## Bounded row examples validated

Validated result/idempotency/rate-limit combinations include:

```text
accepted / accepted / allowed
reused / reused / allowed
rate_limited / none / rate_limited_source
missing_key_denied / missing_key_denied / none
forbidden / none / none
not_found / none / none
```

## Forbidden storage columns

The poll audit table must not contain:

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

## HTTP response lock remains

The existence of poll audit storage does not permit HTTP responses to expose:

```text
audit_event
audit_event_id
audit_primary_key
idempotency_key_id
rate_limit_key_id
raw actor/request/idempotency identifiers
```

## Relationship to current poll runtime

Current poll runtime gates already include:

```text
source_health:poll authorization
missing/empty idempotency_key_hash -> bounded 409
accepted/reused idempotency behavior
rate-limit runtime gate
global/source_key/actor_id_hash counters
bounded 429 response
```

Audit storage is now available for a later runtime write PR, but PR #261 did not wire runtime writes.

## Current known validation

PR #261 validation:

```text
focused poll audit storage test: 5 tests, 0 failures
migration rollback/re-migrate cycle: PASS
adjacent source health/UI/monitoring/poll regression: 124 tests, 0 failures
```

Validated command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_storage_migration_test.exs
```

Adjacent regression command used:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Known unrelated warnings remain:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing unused module attribute/variable warnings
```

## Recommended next PR

Recommended next PR:

```text
Design source health poll audit runtime write flow
```

Recommended scope:

```text
docs-only or test-first design
server-derived route_operation=source_health:poll
accepted/reused/missing_key_denied/rate_limited/forbidden/not_found audit writes
no audit IDs in HTTP responses
audit write failure does not expose raw diagnostics
no provider/materializer/canonical behavior changes
```

Alternative implementation PR if design is already sufficient:

```text
Add source health poll audit runtime write tests
```

Use this only if audit write timing and failure behavior are explicitly scoped.

## Stop conditions

Stop and re-scope if future work:

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

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_audit_storage_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
