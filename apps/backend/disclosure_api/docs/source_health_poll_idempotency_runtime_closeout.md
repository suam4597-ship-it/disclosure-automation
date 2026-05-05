# Source Health Poll Idempotency Runtime Close-out

This document closes out the first source health poll idempotency runtime gate.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 1e08a51cdf5831cc5941bc49f6b096cc9c28eeb3
base source: PR #254 Add source health poll idempotency runtime tests
stream: source health poll idempotency runtime close-out
status: docs-only
```

## Scope closed by PR #254

PR #254 added the first bounded poll idempotency runtime gate.

Closed behavior:

```text
authorized poll requires idempotency_key_hash
missing idempotency_key_hash -> bounded 409
empty idempotency_key_hash -> bounded 409
first source_key + idempotency_key_hash -> accepted idempotency record
repeated source_key + idempotency_key_hash -> bounded reused response
unknown source -> bounded 404
reused path does not execute poll runtime
missing-key path does not execute poll runtime
raw/private/canonical material absent from bounded idempotency responses
```

Changed runtime files from PR #254:

```text
apps/backend/disclosure_api/lib/disclosure_automation/source_health_poll_runtime.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Test file from PR #254:

```text
apps/backend/disclosure_api/test/source_health_poll_idempotency_runtime_test.exs
```

## Explicit non-goals

PR #254 and this close-out do not implement:

```text
rate-limit runtime enforcement
poll audit runtime writes
poll audit read UI
poll UI
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
monitoring/dashboard/alert changes
```

## Runtime helper lock

Helper module:

```text
DisclosureAutomation.SourceHealthPollRuntime
```

Helper entrypoint:

```text
prepare_poll(source_key, attrs)
```

Locked outcomes:

```text
{:error, :not_found}
{:error, :missing_idempotency_key}
{:ok, accepted_poll_response}
{:ok, reused_poll_response}
```

Accepted response shape:

```text
source_key
poll_status=accepted
idempotency_status=accepted
rate_limit_status=allowed
```

Reused response shape:

```text
source_key
poll_status=reused
idempotency_status=reused
rate_limit_status=allowed
```

## Controller behavior lock

Poll controller now gates execution through:

```text
SourceHealthPollRuntime.prepare_poll/2
```

Controller behavior:

```text
accepted -> continue to existing poll execution path
reused -> bounded 202 reused response, no poll execution
missing idempotency key -> bounded 409, no poll execution
unknown source -> bounded 404
```

Bounded missing-key response:

```text
409
error.code=missing_idempotency_key
error.message=poll idempotency key required
```

## Storage lock used by runtime

Runtime uses the poll-specific table:

```text
source_health_poll_idempotency_keys
```

Runtime writes bounded values only:

```text
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
status=accepted
rate_limit_status=allowed
expires_at
last_seen_at
metadata={}
inserted_at
updated_at
```

Runtime does not use recheck idempotency storage.

Recheck table remains separate:

```text
source_health_recheck_idempotency_keys
```

## Redaction lock

Runtime responses and records must not expose:

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
audit_event
audit_event_id
```

## Provider/materializer/canonical boundary

The idempotency gate does not approve provider, materializer, or canonical behavior.

Still not approved by this track:

```text
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
canonical_mutation
```

These strings may appear in unsafe override tests only as negative assertions or existing poll execution parameters. They must not appear in bounded idempotency deny/reused responses.

## Validation evidence

PR #254 validation:

```text
focused poll idempotency runtime test: 6 tests, 0 failures
adjacent source health/UI/monitoring/poll regression: 104 tests, 0 failures
```

Validated cases:

```text
missing key -> 409
empty key -> 409
first accepted record
repeated reused response
unknown source -> 404
reused/missing-key no poll execution
raw/private/canonical material absent
```

Known warnings remain unrelated to PR #254:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing unused module attribute/variable warnings
```

## Recommended final idempotency runtime regression command

Focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_runtime_test.exs
```

Adjacent command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
104 tests, 0 failures
```

## Remaining work after this close-out

Remaining source health poll work should continue as separate gates:

```text
poll rate-limit runtime enforcement
poll audit storage/runtime behavior
poll provider/materializer/canonical impact boundary
poll bounded response close-out
poll operator runbook/smoke test if UI exposure is ever approved
```

Recommended next PR:

```text
Design source health poll rate-limit runtime flow
```

Recommended scope:

```text
docs-only or test-first design
scope priority: global -> source_key -> actor_id_hash
bounded 429 response
rate-limit table update rules
no provider/materializer/canonical changes
no public API/feed changes
```

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
apps/backend/disclosure_api/docs/source_health_poll_idempotency_runtime_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
