# Source Health Poll Audit Runtime Close-out

This document closes out the first bounded source health poll audit runtime write gate.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3f251d7448896b0aaea42acb7648ca053a9db2b2
base source: PR #264 Add source health poll audit runtime write tests
stream: source health poll audit runtime close-out
status: docs-only
```

## Scope closed by PR #264

PR #264 added bounded best-effort source health poll audit runtime writes.

Closed behavior:

```text
accepted outcome audited
reused outcome audited
missing-key outcome audited
rate-limited outcome audited
forbidden outcome audited
not-found outcome audited
route_operation fixed to source_health:poll
HTTP responses do not expose audit IDs
audit rows exclude raw/private/canonical material
HTTP responses exclude raw/private/canonical material
provider/materializer/canonical override material is not exposed
```

Changed runtime files from PR #264:

```text
apps/backend/disclosure_api/lib/disclosure_automation/source_health_poll_runtime.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_poll_authorization.ex
```

Test file from PR #264:

```text
apps/backend/disclosure_api/test/source_health_poll_audit_runtime_test.exs
```

## Explicit non-goals

PR #264 and this close-out do not implement:

```text
poll audit read UI
poll UI
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
monitoring/dashboard/alert changes
```

## Audit runtime write lock

Audit route operation is server-derived and fixed:

```text
source_health:poll
```

Request body cannot override:

```text
route_operation
result_status
idempotency_status
rate_limit_status
audit_event_id
```

## Outcome write lock

Runtime writes bounded audit events for:

```text
accepted
reused
missing_key_denied
rate_limited
forbidden
not_found
```

Mapped status triples:

```text
accepted -> accepted / accepted / allowed
reused -> reused / reused / allowed
missing_key_denied -> missing_key_denied / missing_key_denied / none
rate_limited -> rate_limited / none / rate_limited_source|rate_limited_actor|rate_limited_global
forbidden -> forbidden / none / none
not_found -> not_found / none / none
```

## HTTP response lock

Audit runtime must not add these fields to HTTP responses:

```text
audit_event
audit_event_id
audit_primary_key
idempotency_key_id
rate_limit_key_id
```

Current bounded responses remain:

```text
404 not_found
403 forbidden
409 missing_idempotency_key
429 rate_limited
202 reused
202 accepted or existing poll result for accepted path
```

## Best-effort audit behavior lock

Audit writes are best-effort.

If audit write fails:

```text
HTTP response remains the original bounded response
raw DB errors are not returned
stack traces are not returned
SQL details are not returned
audit failures are not exposed to the caller
```

## Redaction lock

Audit rows and bounded responses must not expose:

```text
raw_provider_payload
full_article_text
headers
cookies
secrets
api_keys
raw_transport_response
sql_details
stack_trace
canonical_payload
private_actor_context
unbounded_diagnostics
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
```

## Provider/materializer/canonical boundary

The audit runtime write gate does not approve provider, materializer, or canonical behavior.

Still not approved by this track:

```text
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
canonical_mutation
```

These may appear in unsafe override tests or existing accepted poll execution parameters only. They must not appear in bounded audit rows or bounded deny/reused responses.

## Validation evidence

PR #264 validation:

```text
focused poll audit runtime test: 7 tests, 0 failures
adjacent source health/UI/monitoring/poll regression: 131 tests, 0 failures
```

Validated cases:

```text
accepted outcome audited
reused outcome audited
missing-key outcome audited
rate-limited outcome audited
forbidden outcome audited
not-found outcome audited
route_operation fixed to source_health:poll
HTTP responses do not expose audit IDs
audit rows exclude raw/private/canonical material
HTTP responses exclude raw/private/canonical material
provider/materializer/canonical override material not exposed
```

Known unrelated warnings remain:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing compile/type warnings
```

## Recommended final audit runtime regression command

Focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_test.exs
```

Adjacent command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
131 tests, 0 failures
```

## Remaining work after this close-out

Remaining source health poll work should continue as separate gates:

```text
poll provider/materializer/canonical impact boundary
poll bounded response final close-out
poll operator runbook/smoke test if UI exposure is ever approved
```

Recommended next PR:

```text
Design source health poll provider materializer canonical impact boundary
```

Recommended scope:

```text
docs-only design first
classify provider/materializer/canonical behavior as forbidden/stubbed/queued/inline
lock no public API/feed shape changes
lock no canonical mutation without explicit design/test gate
lock no poll UI exposure
```

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
apps/backend/disclosure_api/docs/source_health_poll_audit_runtime_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
