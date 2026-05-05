# Source Health Poll Idempotency and Rate Limit Storage Close-out

This document closes out the storage-structure step for future source health poll idempotency and rate limits.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 09c1ccad00f1108ea7c9e42dfa2962b4b456585b
base source: PR #251 Add source health poll idempotency and rate limit storage tests
stream: source health poll idempotency/rate-limit storage close-out
status: docs-only
```

## Scope closed by PR #251

PR #251 added storage structure and tests only.

Closed storage surfaces:

```text
source_health_poll_idempotency_keys
source_health_poll_rate_limits
```

Locked properties:

```text
bounded columns only
source_key + idempotency_key_hash uniqueness
scope + scope_key + window_start_at uniqueness
indexes for source key, expiration/window, status, and rate-limit status
raw/private/canonical columns absent
rollback/migrate cycle validated
```

## Explicit non-goals

PR #251 and this close-out do not implement:

```text
runtime poll idempotency lookup
runtime poll idempotency create/reuse
runtime poll rate-limit enforcement
runtime poll response shape changes
poll audit runtime writes
poll audit read UI
poll UI
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
monitoring/dashboard/alert changes
```

## Poll idempotency table lock

Table:

```text
source_health_poll_idempotency_keys
```

Required bounded columns:

```text
id
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
status
rate_limit_status
expires_at
last_seen_at
metadata
inserted_at
updated_at
```

Required indexes:

```text
sh_poll_idem_source_key_hash_uidx
sh_poll_idem_source_key_idx
sh_poll_idem_expires_at_idx
sh_poll_idem_status_idx
sh_poll_idem_rate_status_idx
```

Unique tuple:

```text
source_key + idempotency_key_hash
```

## Poll rate-limit table lock

Table:

```text
source_health_poll_rate_limits
```

Required bounded columns:

```text
id
scope
scope_key
source_key
actor_id_hash
status
request_count
limit_count
window_start_at
window_expires_at
metadata
inserted_at
updated_at
```

Required indexes:

```text
sh_poll_rate_scope_key_window_uidx
sh_poll_rate_scope_idx
sh_poll_rate_scope_key_idx
sh_poll_rate_window_expires_idx
sh_poll_rate_status_idx
```

Unique tuple:

```text
scope + scope_key + window_start_at
```

## Forbidden storage columns

Neither poll storage table may contain:

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

## Relationship to recheck storage

Poll storage is intentionally separate from recheck storage.

Existing recheck idempotency table:

```text
source_health_recheck_idempotency_keys
```

New poll idempotency table:

```text
source_health_poll_idempotency_keys
```

Do not reuse recheck tables for poll runtime behavior.

Poll idempotency and rate-limit runtime behavior must read/write the poll-specific tables only when implemented in a later runtime PR.

## Current known validation

PR #251 validation:

```text
focused storage migration test: 6 tests, 0 failures
adjacent source health/UI/monitoring/poll regression: 98 tests, 0 failures
rollback/migrate/focused test cycle: passed
```

Validated command set:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs
```

Adjacent regression command used:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Known warnings remain unrelated to PR #251:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing unused module attribute/variable warnings
```

## Recommended next PR

Recommended next PR:

```text
Design source health poll idempotency runtime flow
```

Recommended scope:

```text
docs-only or test-first design
source_key + idempotency_key_hash lookup
missing idempotency_key_hash denial
accepted/reused behavior
rate-limit lookup order
bounded response categories
no provider/materializer/canonical behavior changes
no public API/feed changes
```

Alternative next PR if continuing test-first:

```text
Add source health poll idempotency runtime characterization tests
```

Use this only if the intended runtime behavior is fully specified first.

## Stop conditions

Stop and re-scope if future work:

```text
accepts poll without idempotency_key_hash without explicit exception
stores or returns raw idempotency keys
stores or returns raw actor/request identifiers
stores or returns unredacted reasons
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
exposes audit event IDs
lets request body override operation/action/queue/worker/payload select provider/materializer/canonical behavior
adds poll UI before backend gates are locked
changes public API/feed shapes
adds duplicate controller modules
calls provider clients inline without a design/test gate
triggers materializers inline without a design/test gate
mutates canonical data without a design/test gate
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_idempotency_rate_limit_storage_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
