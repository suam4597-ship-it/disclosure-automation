# Source Health Poll Rate-limit Runtime Close-out

This document closes out the first bounded source health poll rate-limit runtime gate.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 8f69a8818b8d61b66294d089610fc5ea46ebd7b6
base source: PR #257 Add source health poll rate-limit runtime tests
stream: source health poll rate-limit runtime close-out
status: docs-only
```

## Scope closed by PR #257

PR #257 added the first bounded poll rate-limit runtime gate.

Closed behavior:

```text
global rate-limit check
source_key rate-limit check
actor_id_hash rate-limit check
rate-limit check before accepted idempotency record creation
reused idempotency request does not increment counters
missing-key request does not increment counters
unknown-source request does not increment counters
bounded 429 response for rate-limited poll
stable priority: global -> source_key -> actor_id_hash
raw/private/canonical material absent from bounded rate-limit responses
provider/materializer/canonical override material not exposed in bounded rate-limit responses
```

Changed runtime files from PR #257:

```text
apps/backend/disclosure_api/lib/disclosure_automation/source_health_poll_runtime.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Test file from PR #257:

```text
apps/backend/disclosure_api/test/source_health_poll_rate_limit_runtime_test.exs
```

## Explicit non-goals

PR #257 and this close-out do not implement:

```text
poll audit runtime writes
poll audit read UI
poll UI
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
monitoring/dashboard/alert changes
```

## Runtime gate lock

Rate-limit dimensions now checked by the runtime gate:

```text
global
source_key
actor_id_hash
```

Stable priority:

```text
global -> source_key -> actor_id_hash
```

Initial limits:

```text
global -> 100 requests per 60 seconds
source_key -> 5 requests per 60 seconds
actor_id_hash -> 10 requests per 60 seconds
```

These values are intentionally conservative and locked by PR #257 tests.

## Counter increment lock

Counters increment only when all of these are true:

```text
source exists
actor has source_health:poll
idempotency_key_hash is present and non-empty
no active reused idempotency record exists
rate-limit check passes
```

Counters must not increment for:

```text
reused idempotency requests
missing idempotency key requests
forbidden requests
unknown-source requests
```

## Bounded rate-limited response lock

Rate-limited response:

```text
429
error.code=rate_limited
error.message=source poll rate limited
error.rate_limit_status=<bounded_status>
```

Locked bounded statuses:

```text
rate_limited_global
rate_limited_source
rate_limited_actor
```

## Storage interaction lock

Rate-limit runtime uses:

```text
source_health_poll_rate_limits
```

Bounded columns used by runtime include:

```text
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

## Idempotency relationship lock

Rate-limit is checked only for non-reused idempotency keys.

Existing reused behavior remains:

```text
same source_key + idempotency_key_hash inside active window -> reused
reused -> bounded 202
reused -> no poll execution
reused -> no rate-limit counter increment
```

Accepted behavior remains:

```text
new source_key + idempotency_key_hash -> rate-limit check
rate-limit allowed -> accepted idempotency record
accepted -> proceed to existing poll execution path
```

## Provider/materializer/canonical boundary

The rate-limit gate does not approve provider, materializer, or canonical behavior.

Still not approved by this track:

```text
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
canonical_mutation
```

These may appear only in unsafe override tests or existing accepted poll execution parameters. They must not appear in bounded rate-limit responses.

## Validation evidence

PR #257 validation:

```text
focused poll rate-limit runtime test: 8 tests, 0 failures
adjacent source health/UI/monitoring/poll regression: 112 tests, 0 failures
```

Validated cases:

```text
first accepted poll records global/source/actor counters
reused idempotency request does not increment counters
missing-key request does not increment counters
unknown-source request does not increment counters
source_key limit exceeded -> bounded 429
actor_id_hash limit exceeded -> bounded 429
global limit priority over source/actor -> bounded 429 rate_limited_global
body override cannot alter rate-limit decision
raw/private/canonical material absent
```

Known warnings remain unrelated to PR #257:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing unused module attribute/variable warnings
```

## Recommended final rate-limit runtime regression command

Focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_rate_limit_runtime_test.exs
```

Adjacent command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
112 tests, 0 failures
```

## Remaining work after this close-out

Remaining source health poll work should continue as separate gates:

```text
poll audit storage/runtime behavior
poll provider/materializer/canonical impact boundary
poll bounded response close-out
poll operator runbook/smoke test if UI exposure is ever approved
```

Recommended next PR:

```text
Design source health poll audit runtime contract
```

Recommended scope:

```text
docs-only or test-first design
accepted/reused/missing_key_denied/rate_limited/forbidden/not_found audit outcomes
fixed route_operation=source_health:poll
bounded audit storage fields only
no audit event IDs in HTTP responses
no provider/materializer/canonical behavior changes
```

## Stop conditions

Stop and re-scope if future work:

```text
increments counters for reused idempotency requests
increments counters for missing-key requests
increments counters for forbidden requests
increments counters for unknown-source requests
returns raw SQL errors, stack traces, or conflict diagnostics
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reasons
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, canonical payloads, private actor context, or unbounded diagnostics
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
apps/backend/disclosure_api/docs/source_health_poll_rate_limit_runtime_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
