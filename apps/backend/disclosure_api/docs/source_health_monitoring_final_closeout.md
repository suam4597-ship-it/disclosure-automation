# Source Health Monitoring Final Close-out

This document closes out the current bounded source health monitoring and operational visibility track.

This close-out PR is documentation-only. It does not add or modify runtime metric emission, dashboards, alerts, log sinks, routes, controllers, templates, migrations, backend response shapes, poll behavior, audit UI, provider behavior, materializer behavior, canonical behavior, public API/feed behavior, monitoring integrations, or alerting integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 289f290f7be8c2c95e34a233da64aac454b0d20b
base source: PR #243 Add source health monitoring snapshot tests
stream: source health monitoring final close-out
status: docs-only
```

## Scope closed by this track

This monitoring track closes the bounded monitoring contract layer for source health.

Closed surfaces:

```text
monitoring design
monitoring metric contract tests
bounded pure monitoring helper allowlists
monitoring runbook
monitoring snapshot contract tests
raw/private/canonical monitoring denylist
poll/provider/materializer/canonical out-of-scope guardrails
```

This close-out does not implement or close:

```text
runtime metric emission
metric storage
dashboards
alerts
log sinks
monitoring integrations
audit read UI
poll route gated stream
public source health UI
```

## Locked helper module

Helper module:

```text
apps/backend/disclosure_api/lib/disclosure_automation/source_health_monitoring.ex
```

Locked helper functions:

```text
metric_names()
metric_labels()
result_statuses()
idempotency_statuses()
freshness_buckets()
structured_log_keys()
contract()
snapshot_sections()
snapshot_contract()
```

The helper is a pure allowlist/contract helper.

It must not:

```text
emit telemetry
write logs
query Repo
call providers
enqueue jobs
call poll routes
render dashboards
send alerts
mutate canonical data
```

## Locked monitoring contracts

Metric names stay under:

```text
source_health.*
```

Metric labels remain bounded.

Result statuses remain:

```text
accepted
reused
untracked
forbidden
not_found
error
```

Idempotency statuses remain:

```text
accepted
reused
untracked
none
```

Freshness buckets remain:

```text
under_15m
15m_to_1h
1h_to_6h
6h_to_24h
over_24h
never
```

Structured log keys remain bounded/hash-safe:

```text
actor_id_hash
event
http_status
idempotency_status
occurred_at
redaction_status
request_id_hash
result_status
route_operation
source_key
```

## Locked snapshot contract

Snapshot helper:

```text
snapshot_contract()
```

Locked sections:

```text
overview
freshness
recheck_operations
idempotency
audit_outcomes
operator_smoke
ui_regression
```

Locked non-runtime flags:

```text
runtime_emission=false
dashboards=false
alerts=false
log_sinks=false
poll_route=out_of_scope
```

The snapshot contract is an in-memory shape only. It must not emit metrics, write logs, query storage, render dashboards, trigger alerts, or touch poll/provider/materializer/canonical behavior.

## Monitoring runbook lock

Runbook file:

```text
apps/backend/disclosure_api/docs/source_health_monitoring_runbook.md
```

The runbook now covers:

```text
source health overview panel interpretation
freshness panel interpretation
recheck operations panel interpretation
idempotency panel interpretation
audit outcome aggregate interpretation
operator smoke/regression status interpretation
alert response guide
bounded structured log key guidance
operator escalation allowlist and denylist
```

## Redaction and forbidden material lock

Monitoring contracts, helpers, snapshot tests, and runbooks must not introduce:

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

These terms may appear only in explicit denylist, forbidden, or stop-condition contexts.

## Out-of-scope behavior lock

The monitoring track must not introduce:

```text
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

The poll route remains a separate gated stream:

```text
POST /api/admin/sources/:source_key/poll
```

## Validation evidence across this track

Recent validations include:

```text
PR #240 focused monitoring contract test: 5 tests, 0 failures
PR #240 adjacent source health/UI regression: 66 tests, 0 failures
PR #241 focused monitoring helper/contract tests: 10 tests, 0 failures
PR #241 adjacent source health/UI regression: 71 tests, 0 failures
PR #243 focused monitoring snapshot/helper tests: 14 tests, 0 failures
PR #243 adjacent source health/UI regression: 75 tests, 0 failures
```

Docs-only monitoring PRs:

```text
PR #239 Design source health monitoring and operational visibility
PR #242 Add source health monitoring runbook
```

Known warning status:

```text
existing compile warnings remain
existing Phoenix.ConnTest deprecation warning remains
no new duplicate source health controller warning was validated in recent test runs
```

## Recommended final monitoring regression command

Focused monitoring regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs
```

Adjacent source health/UI regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
75 tests, 0 failures
```

## Remaining work after this close-out

After this monitoring close-out, remaining source health work should be tracked separately:

```text
poll route gated stream
audit read UI if needed
production auth/session model replacement for request-param test harness
actual telemetry/dashboard/alert implementation if required by a future dedicated monitoring runtime track
```

## Recommended next PR

Recommended next PR if continuing the original remaining-work list:

```text
Design source health poll route gated stream
```

Recommended scope:

```text
docs-only design first
explicitly separate poll from recheck
permission model
idempotency/rate-limit model
provider/materializer/canonical impact analysis
public response impact analysis
rollback and stop conditions
no runtime poll changes yet
```

Alternative if poll is deferred:

```text
Design source health audit read UI
```

Only choose audit read UI if operators need bounded aggregate audit visibility beyond existing internal audit writes.

## Stop conditions for future work

Stop and re-scope if future work:

```text
emits raw actor/request/idempotency identifiers
emits unredacted reason
emits headers, cookies, tokens, or provider credentials
emits raw provider payloads, full article text, raw transport responses, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
exposes audit event IDs in operator dashboards
adds poll UI or poll controls without a dedicated poll gate
adds provider/materializer/canonical controls
changes backend response shapes without a contract PR
adds public source health routes
adds duplicate controller modules
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation for this close-out PR

This final close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_monitoring_final_closeout.md
```

No Codex test command is required for this docs-only final close-out PR.
