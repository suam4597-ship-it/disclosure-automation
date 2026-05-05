# Source Health Monitoring Runbook

This runbook describes bounded operational use of source health monitoring signals after the monitoring design and pure helper allowlists were added.

This PR is documentation-only. It does not add or modify runtime metric emission, dashboards, alerts, log sinks, routes, controllers, templates, migrations, backend response shapes, poll behavior, audit UI, provider behavior, materializer behavior, canonical behavior, public API/feed behavior, or monitoring integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 105d5a1bfbe77e38739d815d57c5b16f45511fae
base source: PR #241 Add bounded source health monitoring helpers
stream: source health monitoring runbook
status: docs-only
```

## Audience

This runbook is for operators and developers reviewing bounded source health monitoring signals.

It assumes the current monitoring surface is still a contract/helper layer, not a live dashboard or alerting system.

## Current locked building blocks

Design doc:

```text
apps/backend/disclosure_api/docs/source_health_monitoring_operational_visibility_design.md
```

Pure helper module:

```text
apps/backend/disclosure_api/lib/disclosure_automation/source_health_monitoring.ex
```

Contract/helper tests:

```text
apps/backend/disclosure_api/test/source_health_monitoring_contract_test.exs
apps/backend/disclosure_api/test/source_health_monitoring_helpers_test.exs
```

Current known validation:

```text
PR #240 focused monitoring contract test: 5 tests, 0 failures
PR #240 adjacent source health/UI regression: 66 tests, 0 failures
PR #241 focused monitoring helper/contract tests: 10 tests, 0 failures
PR #241 adjacent source health/UI regression: 71 tests, 0 failures
```

## Scope

This runbook covers how to interpret and operate future bounded monitoring signals for:

```text
source health inventory
source health freshness
source health recheck requests
source health recheck responses
source health recheck idempotency
source health recheck audit outcomes
operator smoke/regression status
```

It does not authorize:

```text
poll route operation
poll UI
provider fetch actions
materializer actions
canonical mutation actions
audit read UI
public source health UI
raw diagnostic dashboards
```

## Safety principles

Monitoring must remain bounded.

Operators may use:

```text
counts
rates
bounded status labels
bounded source_key where already operator-visible
bounded route_operation
bounded result_status
bounded idempotency_status
bounded health_status
bounded timestamps and age buckets
bounded redaction_status
```

Operators must not use or request:

```text
raw actor IDs
raw request IDs
raw idempotency keys
unredacted reasons
headers
cookies
tokens
provider credentials
raw provider payloads
full article text
raw transport responses
SQL details
stack traces
canonical payloads
private actor context
unbounded diagnostic blobs
audit event identifiers in operator UI
```

## Approved helper surfaces

The source health monitoring helper exposes allowlists only:

```text
metric_names()
metric_labels()
result_statuses()
idempotency_statuses()
freshness_buckets()
structured_log_keys()
contract()
```

The helper must remain side-effect free.

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

## Dashboard section: Source health overview

Future dashboards may show:

```text
total sources
active sources
inactive sources
sources by health_status
sources by source_type
sources by region_code
stale source count
recent failure count
never-success count
```

Operator interpretation:

```text
high stale count -> inspect freshness panel and source detail UI
high recent failure count -> inspect affected source health detail pages
never-success count rising -> check onboarding or source registry state
```

Do not display:

```text
raw source config
provider credentials
raw URLs with secrets
headers
cookies
provider payloads
full article text
stack traces
SQL details
```

## Dashboard section: Freshness

Approved freshness buckets:

```text
under_15m
15m_to_1h
1h_to_6h
6h_to_24h
over_24h
never
```

Future dashboard panels may show:

```text
last_success_age_seconds
last_failure_age_seconds
sources by freshness_bucket
stale sources by source_type
stale sources by region_code
```

Operator interpretation:

```text
over_24h active source -> inspect source detail and consider bounded recheck if authorized
never active source -> verify source registry setup and source class
recent failure with old success -> escalate bounded source_key and status metadata
```

Do not infer raw provider failure details from freshness metrics.

## Dashboard section: Recheck operations

Approved recheck result statuses:

```text
accepted
reused
untracked
forbidden
not_found
error
```

Future dashboard panels may show:

```text
recheck requests over time
202 accepted/reused/untracked count
403 forbidden count
404 not_found count
unexpected error count
idempotency reuse ratio
```

Operator interpretation:

```text
accepted rising -> normal operator recheck activity or incident-driven usage
reused rising -> repeated submissions are being deduped; avoid repeated clicks
untracked rising -> idempotency key generation or propagation may need review
forbidden rising -> permission or stale UI state issue may need review
not_found rising -> source_key mismatch or removed source references may need review
error rising -> inspect bounded logs and route health
```

Do not display raw request payloads, raw actor IDs, raw request IDs, raw idempotency keys, unredacted reasons, or job internals.

## Dashboard section: Idempotency

Approved idempotency statuses:

```text
accepted
reused
untracked
none
```

Future dashboard panels may show:

```text
idempotency accepted count
idempotency reused count
idempotency untracked count
idempotency reuse ratio
```

Operator interpretation:

```text
accepted -> new tracked requests are being accepted
reused -> duplicate tracked requests are being safely deduped
untracked -> request was accepted without idempotency storage
none -> no idempotency status was available for the event class
```

Do not expose idempotency record IDs or raw idempotency keys.

## Dashboard section: Audit outcome visibility

Future aggregate panels may show bounded counts for:

```text
accepted
reused
untracked
forbidden
not_found
```

Allowed labels:

```text
route_operation
result_status
idempotency_status
source_key
```

Do not expose:

```text
audit_event_id
audit event primary key
raw actor/request/idempotency identifiers
unredacted reasons
raw payloads
```

Audit read UI is still a separate future track.

## Dashboard section: Operator smoke and regression

Future panels may show:

```text
source_health.operator_smoke.last_result
source_health.operator_smoke.last_success_at
source_health.operator_smoke.failure_total
source_health.ui_regression.last_result
source_health.ui_regression.last_success_at
source_health.ui_regression.failure_total
```

Operator interpretation:

```text
operator smoke failed -> pause source health UI rollout and inspect bounded test output
UI regression failed -> do not merge dependent UI/monitoring PRs until resolved
last_success_at old -> rerun local/Codex validation before relying on current signal
```

Do not paste raw CI logs with secrets, stack traces, SQL details, headers, cookies, or tokens into dashboards or tickets.

## Alert response guide

### source_health_stale_warning / source_health_stale_critical

Operator action:

```text
1. Open /admin/source-health.
2. Locate affected source_key if available.
3. Open /admin/source-health/:source_key.
4. Confirm health_status, last_success_at, last_failure_at, active.
5. If authorized and appropriate, use bounded recheck path only.
6. Escalate bounded source metadata if stale condition persists.
```

Do not trigger poll route as part of this alert response.

### source_health_recheck_forbidden_spike

Operator action:

```text
1. Confirm whether read-only operators are attempting recheck.
2. Verify permission state and UI guidance.
3. Escalate bounded counts and affected source_key if available.
```

Do not bypass authorization with operation, queue, worker, or payload overrides.

### source_health_recheck_not_found_spike

Operator action:

```text
1. Check whether source keys were renamed or removed.
2. Confirm source registry state through bounded source health UI/API.
3. Escalate bounded missing source_key counts only.
```

### source_health_recheck_untracked_spike

Operator action:

```text
1. Check idempotency_key_hash generation/propagation in the bounded UI flow.
2. Avoid repeated recheck submissions.
3. Escalate bounded request_id_hash/redaction_status if available.
```

Do not expose raw idempotency keys.

### source_health_operator_smoke_failed

Operator action:

```text
1. Run focused smoke test locally or in Codex.
2. Confirm no route or response shape drift.
3. Confirm raw/private/canonical denylist still passes.
4. Pause dependent monitoring/dashboard work until green.
```

## Bounded structured log event guidance

Approved future log keys:

```text
event
route_operation
source_key
result_status
idempotency_status
http_status
redaction_status
request_id_hash
actor_id_hash
occurred_at
```

Forbidden future log keys:

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

## Operator escalation checklist

Escalation may include:

```text
source_key
source_type
region_code
health_status
freshness_bucket
last_success_age bucket
last_failure_age bucket
result_status
idempotency_status
http_status
redaction_status
request_id_hash
actor_id_hash
occurred_at bucket
```

Escalation must not include:

```text
raw actor ID
raw request ID
raw idempotency key
unredacted reason
headers
cookies
tokens
provider credentials
raw provider payload
full article text
raw transport response
SQL details
stack traces
canonical payload
private actor context
unbounded diagnostics
audit event IDs
```

## Validation commands

Focused monitoring helper/contract validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs
```

Adjacent source health/UI regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known validation:

```text
focused monitoring helper/contract tests: 10 tests, 0 failures
adjacent source health/UI regression: 71 tests, 0 failures
```

## Remaining work after this runbook

Recommended next implementation track:

```text
Add source health monitoring snapshot tests
```

Recommended scope:

```text
test-only or pure helper first
build bounded in-memory snapshot shape from helper allowlists
no runtime metric emission
no dashboards
no alerts
no logs
poll route remains out of scope
```

Alternative if monitoring is deferred:

```text
Design source health poll route gated stream
```

Only choose the poll stream when ready to explicitly design/test gate poll behavior.

## Stop conditions

Stop and re-scope if future monitoring work:

```text
emits raw actor/request/idempotency identifiers
emits unredacted reason
emits headers, cookies, tokens, or provider credentials
emits raw provider payloads, full article text, raw transport responses, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
exposes audit event IDs in operator dashboards
adds poll UI or poll controls
adds provider/materializer/canonical controls
changes backend response shapes
adds public source health routes
adds duplicate controller modules
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation for this runbook PR

This runbook PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_monitoring_runbook.md
```

No Codex test command is required for this docs-only runbook PR.
