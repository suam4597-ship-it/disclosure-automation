# Source Health Poll Authorization Contract

This document defines the authorization contract for the future source health poll gated stream.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f4cf00b61d50141162794c5f4b1630e4ae08792a
base source: PR #246 Add source health poll route gated characterization tests
stream: source health poll authorization contract
status: docs-only contract
```

## Existing route

Existing poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Existing target:

```text
DisclosureAutomationWeb.AdminSourcePollController.create/2
```

This contract does not add, remove, rename, or retarget the route.

## Authorization goal

Poll must be protected by a distinct permission.

Candidate permission:

```text
source_health:poll
```

The following permissions must not be sufficient to poll:

```text
source_health:read
source_health:recheck
```

Rationale:

```text
source_health:read is observational only
source_health:recheck is bounded to health_checks recheck behavior
source_health:poll may affect source runtime behavior and must be gated separately
```

## Locked authorization outcomes for future implementation

Future implementation should lock:

```text
unknown source -> bounded 404
source_health:read -> bounded 403 for existing source poll
source_health:recheck -> bounded 403 for existing source poll
missing actor_permissions -> bounded 403 for existing source poll
source_health:poll -> may reach bounded poll path only after all other gates are satisfied
```

Unknown-source behavior should remain bounded and must not leak whether a caller would otherwise be authorized beyond the existing not-found contract.

## Permission matrix

```text
actor_permissions=[] -> 403 for existing source
actor_permissions=[source_health:read] -> 403 for existing source
actor_permissions=[source_health:recheck] -> 403 for existing source
actor_permissions=[source_health:read, source_health:recheck] -> 403 for existing source
actor_permissions=[source_health:poll] -> allowed only after remaining poll gates pass
actor_permissions=[source_health:poll, source_health:read] -> allowed only after remaining poll gates pass
```

Poll authorization must not be inferred from source health UI access.

## Body override bypass prevention

Request body fields must not be able to bypass authorization.

Forbidden bypass fields:

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

Even if these fields are present, an actor without `source_health:poll` must receive bounded 403 for an existing source.

## Bounded request context

Future authorization checks may consume only bounded actor context:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Authorization must not require raw actor identifiers, raw request IDs, raw idempotency keys, unredacted reasons, headers, cookies, tokens, or provider credentials.

## Bounded forbidden response

Future forbidden response should be:

```text
403
error.code=forbidden
error.message=source poll not allowed
```

The response must not include:

```text
job_id
queue
args
worker
accepted
scheduled_at
provider payloads
full article text
raw transport response
headers
cookies
tokens
provider credentials
SQL details
stack traces
canonical payloads
private actor context
unbounded diagnostics
raw actor/request/idempotency identifiers
audit event IDs
```

## Unknown source behavior

Current characterization lock:

```text
POST /api/admin/sources/:missing_source_key/poll -> bounded 404
error.code=not_found
error.message=source not found
```

Future authorization work must preserve bounded unknown-source behavior.

## Audit expectation

Future poll authorization denials should be auditable through bounded internal audit storage before routine operation.

Candidate audit outcomes:

```text
forbidden
not_found
```

Audit route operation should be fixed as:

```text
source_health:poll
```

Request body must not be able to override audit route operation.

Audit storage must not persist raw/private/canonical material.

## UI exposure policy

Poll UI remains forbidden until backend authorization, idempotency/rate-limit, audit, response shape, and provider/materializer/canonical impact gates are all locked.

Internal UI should continue to avoid:

```text
poll_action=enabled
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

## Recommended future test file

Recommended next test file:

```text
apps/backend/disclosure_api/test/source_health_poll_authorization_contract_test.exs
```

Recommended test cases:

```text
read-only actor cannot poll existing source
recheck-only actor cannot poll existing source
missing permission actor cannot poll existing source
body override cannot bypass poll authorization
unknown source remains bounded 404
forbidden response does not expose raw/private/canonical material
```

The first implementation PR may be test-first and should not add UI controls.

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_authorization_contract_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before authorization work:

```text
80 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future poll authorization work:

```text
lets source_health:read trigger poll
lets source_health:recheck trigger poll
lets missing actor_permissions trigger poll
allows body override to bypass authorization
adds poll UI before backend gates are locked
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reason
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
exposes audit event IDs
changes public API/feed shapes
adds duplicate controller modules
calls provider clients inline without a design/test gate
triggers materializers inline without a design/test gate
mutates canonical data without a design/test gate
```

## Validation for this contract PR

This contract PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_authorization_contract.md
```

No Codex test command is required for this docs-only contract PR.
