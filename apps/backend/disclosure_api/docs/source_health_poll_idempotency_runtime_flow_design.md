# Source Health Poll Idempotency Runtime Flow Design

This document designs the future runtime flow for source health poll idempotency and rate limits after poll authorization and poll storage have been locked.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 400d53ee63ae867b755fa15ef0053c5c55ecc912
base source: PR #252 Document source health poll storage close-out
stream: source health poll idempotency runtime flow design
status: docs-only design
```

## Existing locked prerequisites

Poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Poll route target:

```text
DisclosureAutomationWeb.AdminSourcePollController.create/2
```

Poll authorization:

```text
source_health:poll required for existing source poll
source_health:read is not enough
source_health:recheck is not enough
unknown source remains bounded 404
```

Poll storage tables:

```text
source_health_poll_idempotency_keys
source_health_poll_rate_limits
```

This design assumes those gates are present before runtime idempotency/rate-limit behavior is implemented.

## Runtime flow goal

Define a safe runtime flow for poll idempotency and rate limits without approving provider/materializer/canonical behavior.

The runtime flow should decide whether a poll request is allowed to proceed to the existing bounded poll path based on:

```text
source existence
authorization
bounded request context
idempotency_key_hash presence
active idempotency record lookup
rate-limit checks
bounded response category
```

## Non-goals

This design does not approve:

```text
provider client calls
inline provider fetch
materializer execution
canonical mutation
public feed rebuilds
poll UI
audit read UI
raw diagnostic responses
runtime metric emission
```

## Required request context

Runtime may use only:

```text
source_key
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Runtime must not require or persist:

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

## High-level runtime order

Future runtime should follow this order:

```text
1. route match
2. source lookup
3. authorization check
4. request context normalization
5. idempotency_key_hash presence check
6. active idempotency lookup
7. rate-limit checks
8. accept/reuse/deny response decision
9. bounded audit write if audit runtime has been approved
10. existing poll behavior only if all gates pass
```

Current design only specifies the idempotency/rate-limit decisions. It does not approve audit runtime or provider/materializer/canonical behavior.

## Step 1: source lookup

Unknown source behavior remains:

```text
404
error.code=not_found
error.message=source not found
```

Unknown source must not create idempotency records or rate-limit records.

## Step 2: authorization check

Existing source without `source_health:poll` remains:

```text
403
error.code=forbidden
error.message=source poll not allowed
```

Unauthorized requests must not create idempotency records or rate-limit records unless a future audit-only design explicitly allows bounded denial audit writes.

## Step 3: idempotency key presence

Poll should require idempotency.

Missing or empty idempotency key should return a bounded denial before rate-limit state mutation:

```text
409
error.code=missing_idempotency_key
error.message=poll idempotency key required
```

Alternative acceptable status if project convention prefers bad request:

```text
400
error.code=missing_idempotency_key
error.message=poll idempotency key required
```

The implementation PR must choose one status and lock it with tests before runtime launch.

Recommended default:

```text
409 Conflict
```

## Step 4: active idempotency lookup

Lookup key:

```text
source_key + idempotency_key_hash
```

Active record predicate:

```text
expires_at > now
```

If active record exists:

```text
poll_status=reused
idempotency_status=reused
rate_limit_status=<stored-or-derived bounded status>
```

Recommended response:

```text
202
source_key=<source_key>
poll_status=reused
idempotency_status=reused
rate_limit_status=allowed
```

Do not enqueue, call provider, materialize, or mutate canonical state on a reused request.

## Step 5: rate-limit checks

If no active idempotency record exists, check rate limits in stable priority order:

```text
global
source_key
actor_id_hash
region_code
source_type
```

Required first implementation dimensions:

```text
global
source_key
actor_id_hash
```

Optional later dimensions:

```text
region_code
source_type
```

If a limit is exceeded, return bounded 429 without creating an accepted idempotency record.

Recommended response:

```text
429
error.code=rate_limited
error.message=source poll rate limited
rate_limit_status=<bounded_status>
```

Allowed rate-limit statuses:

```text
rate_limited_global
rate_limited_source
rate_limited_actor
rate_limited_region
rate_limited_source_type
```

Rate-limit denial may write/update rate-limit table state, but must not call provider, materializer, canonical mutation, or public feed rebuild behavior.

## Step 6: accepted path

If idempotency key is present, no active idempotency record exists, and rate limits pass, future runtime may create a poll idempotency record.

Accepted idempotency record values:

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
```

Recommended response category:

```text
202
source_key=<source_key>
poll_status=accepted
idempotency_status=accepted
rate_limit_status=allowed
```

Only after this decision may the request proceed to the separately approved bounded poll behavior.

This design does not approve what poll does after acceptance.

## Step 7: expired record behavior

If an idempotency record exists but is expired:

```text
expires_at <= now
```

Treat it as not active.

Recommended behavior:

```text
create or replace bounded accepted record for the new window
idempotency_status=accepted
```

Expired cleanup can be a later maintenance job.

## Response shape lock

Allowed response categories:

```text
accepted
reused
missing_idempotency_key
rate_limited
forbidden
not_found
```

Forbidden response fields:

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

## Body override handling

The following request body fields must not influence idempotency/rate-limit decisions:

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

Future implementation may either:

```text
ignore these fields for idempotency/rate-limit decisions
reject these fields with bounded invalid_request
```

Recommended first implementation:

```text
ignore for idempotency/rate-limit decisions, continue to deny/allow based only on bounded contract fields
```

Provider/materializer/canonical behavior must still remain separately gated.

## Audit interaction

Audit runtime is not implemented by this design.

When audit runtime is later approved, audit outcomes should include:

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

Audit route operation must remain:

```text
source_health:poll
```

## Test plan for future runtime implementation

Recommended next test file:

```text
apps/backend/disclosure_api/test/source_health_poll_idempotency_runtime_test.exs
```

Recommended tests:

```text
missing idempotency_key_hash returns bounded 409
empty idempotency_key_hash returns bounded 409
first authorized poll with idempotency_key_hash returns accepted category
repeat authorized poll with same source_key + idempotency_key_hash returns reused category
repeat authorized poll does not advance provider/materializer/canonical behavior
rate-limit exceeded returns bounded 429
body override cannot alter idempotency/rate-limit decision
unknown source creates no idempotency/rate-limit records
forbidden actor creates no idempotency/rate-limit records
raw/private/canonical material is absent from all responses
```

Initial runtime PR may stop at idempotency accepted/reused/missing-key behavior and leave rate-limit runtime as contract-only if needed.

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_runtime_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before runtime flow work:

```text
98 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future runtime work:

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

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_idempotency_runtime_flow_design.md
```

No Codex test command is required for this docs-only design PR.
