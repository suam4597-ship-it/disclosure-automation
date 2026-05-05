# Source Health Monitoring and Operational Visibility Design

This document designs a bounded monitoring and operational visibility track for source health after the internal UI final close-out.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, dashboards, metrics emitters, log sinks, alert rules, or monitoring integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 121ad009228797c591d189778582074f934d75c2
base source: PR #238 Add source health internal UI final close-out
stream: source health monitoring and operational visibility design
status: docs-only design
```

## Goal

Design bounded source health monitoring that lets operators see whether source health and recheck workflows are functioning without exposing raw/private/canonical material or expanding poll/provider/materializer behavior.

The design should support:

```text
source health freshness visibility
recheck request volume visibility
recheck result status visibility
idempotency status visibility
authorization denial visibility
unknown-source attempt visibility
bounded audit outcome visibility
operator smoke/regression health visibility
```

## Non-goals

This design does not implement:

```text
metrics emission
metrics storage
dashboards
alerts
log pipelines
audit read API
audit UI
new routes
backend response shape changes
poll route changes
poll UI
provider fetch behavior
materializer behavior
canonical mutation behavior
public API/feed changes
```

## Existing locked surfaces

Internal UI routes:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Bounded backend recheck route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Still gated and out of scope:

```text
POST /api/admin/sources/:source_key/poll
```

## Monitoring safety principles

Monitoring must remain bounded.

Allowed monitoring data classes:

```text
counts
rates
status labels
bounded source_key labels where already operator-visible
bounded route_operation labels
bounded result_status labels
bounded idempotency_status labels
bounded health_status labels
timestamps and age buckets
redaction_status labels
```

Forbidden monitoring data classes:

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

## Proposed metric groups

### Source health inventory metrics

Candidate bounded metrics:

```text
source_health.sources.total
source_health.sources.active_total
source_health.sources.inactive_total
source_health.sources.by_status
source_health.sources.by_type
source_health.sources.by_region
```

Suggested labels:

```text
health_status
source_type
region_code
active
```

Do not label with raw URLs, provider credentials, raw errors, headers, cookies, tokens, or unbounded config.

### Source health freshness metrics

Candidate bounded metrics:

```text
source_health.last_success_age_seconds
source_health.last_failure_age_seconds
source_health.sources.stale_total
source_health.sources.never_success_total
source_health.sources.recent_failure_total
```

Suggested labels:

```text
source_key
source_type
region_code
health_status
freshness_bucket
```

Suggested freshness buckets:

```text
under_15m
15m_to_1h
1h_to_6h
6h_to_24h
over_24h
never
```

Do not emit raw failure body, raw transport response, stack trace, SQL detail, or provider payload.

### Recheck request metrics

Candidate bounded metrics:

```text
source_health.recheck.requests.total
source_health.recheck.responses.total
source_health.recheck.accepted.total
source_health.recheck.forbidden.total
source_health.recheck.not_found.total
source_health.recheck.errors.total
```

Suggested labels:

```text
route_operation=source_health:recheck
result_status
http_status
source_key
```

Allowed result statuses:

```text
accepted
reused
untracked
forbidden
not_found
error
```

Do not include raw request IDs, raw actor IDs, raw idempotency keys, unredacted reasons, or raw backend payloads.

### Idempotency metrics

Candidate bounded metrics:

```text
source_health.recheck.idempotency.total
source_health.recheck.idempotency.accepted_total
source_health.recheck.idempotency.reused_total
source_health.recheck.idempotency.untracked_total
source_health.recheck.idempotency.reuse_ratio
```

Suggested labels:

```text
source_key
idempotency_status
```

Allowed idempotency statuses:

```text
accepted
reused
untracked
none
```

Do not expose raw idempotency key or idempotency record ID.

### Audit outcome metrics

The backend already writes bounded source health recheck audit events internally.

Candidate bounded metrics derived from audit storage:

```text
source_health.recheck.audit.events.total
source_health.recheck.audit.accepted.total
source_health.recheck.audit.reused.total
source_health.recheck.audit.untracked.total
source_health.recheck.audit.forbidden.total
source_health.recheck.audit.not_found.total
```

Suggested labels:

```text
route_operation
result_status
idempotency_status
source_key
```

Do not expose audit event IDs in operator UI or metric labels.

### Operator smoke/regression visibility

Candidate bounded signals:

```text
source_health.operator_smoke.last_result
source_health.operator_smoke.last_success_at
source_health.operator_smoke.failure_total
source_health.ui_regression.last_result
source_health.ui_regression.last_success_at
source_health.ui_regression.failure_total
```

Suggested labels:

```text
test_group
result
```

Known validation baseline at this point:

```text
focused operator smoke test: 6 tests, 0 failures
adjacent source health/UI regression: 61 tests, 0 failures
```

Do not include raw test logs containing stack traces or environment secrets in operator dashboards.

## Proposed dashboard sections

### Section 1: Source health overview

Display:

```text
total sources
active sources
sources by health_status
sources by source_type
sources by region_code
stale source count
recent failure count
never-success count
```

Do not display raw source config, provider credentials, raw URLs with secrets, headers, cookies, or provider payloads.

### Section 2: Recheck operations

Display:

```text
recheck requests over time
202 accepted/reused/untracked count
403 forbidden count
404 not_found count
unexpected error count
idempotency reuse ratio
```

Do not display raw request payloads, raw actor IDs, raw request IDs, raw idempotency keys, unredacted reasons, or job internals.

### Section 3: Operator safety checks

Display:

```text
read-only denied count
unknown-source attempt count
untracked idempotency count
raw/private/canonical exposure check status
route inventory check status
operator smoke test status
```

Do not display audit event IDs or raw test failure diagnostics.

### Section 4: Follow-up queue

Display bounded triage suggestions:

```text
sources stale beyond threshold
sources with repeated recent failures
sources with frequent recheck reuse
sources with frequent forbidden attempts
sources with frequent not_found attempts
```

Do not add direct poll actions, provider fetch actions, materializer actions, or canonical mutation actions.

## Proposed alert classes

### Freshness alerts

Candidate alerts:

```text
source_health_stale_warning
source_health_stale_critical
source_health_never_success_warning
```

Suggested inputs:

```text
last_success_age_seconds
health_status
active
source_type
region_code
```

Alert payload must not include raw failure body, stack trace, SQL detail, raw provider payload, or credentials.

### Recheck failure alerts

Candidate alerts:

```text
source_health_recheck_forbidden_spike
source_health_recheck_not_found_spike
source_health_recheck_untracked_spike
source_health_recheck_error_spike
```

Suggested inputs:

```text
result_status counts
idempotency_status counts
http_status counts
source_key if bounded and operator-visible
```

Do not include raw actor IDs, request IDs, idempotency keys, or unredacted reasons.

### Operator smoke alerts

Candidate alerts:

```text
source_health_operator_smoke_failed
source_health_ui_regression_failed
```

Alert payload should include:

```text
test_group
result
bounded failure category
commit SHA if available
```

Do not include raw logs with secrets or stack traces in alert payloads.

## Bounded log event design

If future work adds structured logs, logs should use bounded keys only.

Approved log keys:

```text
event=source_health_recheck
route_operation=source_health:recheck
source_key
result_status
idempotency_status
http_status
redaction_status
request_id_hash
actor_id_hash
occurred_at
```

Forbidden log keys:

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

## Future implementation PR sequence

Recommended implementation sequence:

```text
1. Add source health monitoring metric contract tests
2. Add bounded source health monitoring metric helpers
3. Add source health monitoring dashboard/runbook doc
4. Add source health monitoring close-out
```

Start with tests or docs before runtime emitters.

## Future metric contract test design

Recommended future test file:

```text
apps/backend/disclosure_api/test/source_health_monitoring_contract_test.exs
```

Test goals:

```text
approved metric names are documented
approved labels are bounded
forbidden labels are rejected or absent
result_status values are bounded
idempotency_status values are bounded
raw/private/canonical material is absent
poll/provider/materializer/canonical metrics are not introduced in this track
```

Potential forbidden label assertions:

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

## Validation commands for future implementation PRs

Future focused monitoring contract validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_monitoring_contract_test.exs
```

Future adjacent source health/UI regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before monitoring implementation:

```text
61 tests, 0 failures
```

## Poll route remains out of scope

Do not add monitoring that encourages operators to trigger poll as part of this source health recheck monitoring track.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

Forbidden controls/actions in this track:

```text
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

Poll monitoring must be designed later as part of the poll route gated stream.

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

## Recommended next PR

Recommended next PR:

```text
Add source health monitoring metric contract tests
```

Recommended scope:

```text
test-only if possible
metric names and label allowlist
forbidden label/material denylist
no runtime emitters yet
no dashboards yet
poll route remains out of scope
```

Alternative if monitoring is deferred:

```text
Design source health poll route gated stream
```

Only choose the poll stream when ready to explicitly design/test gate poll behavior.

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_monitoring_operational_visibility_design.md
```

No Codex test command is required for this docs-only design PR.
