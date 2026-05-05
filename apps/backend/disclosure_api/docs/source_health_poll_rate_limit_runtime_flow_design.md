# Source Health Poll Rate-limit Runtime Flow Design

This document designs the future runtime rate-limit flow for the source health poll gated stream after poll authorization, storage, and idempotency runtime behavior have been locked.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 1770c3c2f5ee185629c95fb9e1a2cccf5bb53cc2
base source: PR #255 Add source health poll idempotency runtime close-out
stream: source health poll rate-limit runtime flow design
status: docs-only design
```

## Existing locked prerequisites

Poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Poll authorization:

```text
source_health:poll required
source_health:read is not enough
source_health:recheck is not enough
unknown source remains bounded 404
```

Poll idempotency runtime:

```text
missing/empty idempotency_key_hash -> bounded 409
first source_key + idempotency_key_hash -> accepted idempotency record
repeat source_key + idempotency_key_hash -> bounded reused response without poll execution
```

Poll storage tables:

```text
source_health_poll_idempotency_keys
source_health_poll_rate_limits
```

## Goal

Define a bounded rate-limit runtime flow that can run after source lookup, authorization, idempotency key presence, and active idempotency lookup.

The rate-limit gate should prevent excessive poll execution without exposing raw/private/canonical data or approving provider/materializer/canonical behavior.

## Non-goals

This design does not implement or approve:

```text
runtime rate-limit enforcement
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

## Required first dimensions

First runtime implementation should check these dimensions:

```text
global
source_key
actor_id_hash
```

Optional future dimensions:

```text
region_code
source_type
```

Do not require raw actor IDs, raw request IDs, raw idempotency keys, headers, cookies, tokens, provider credentials, or raw provider payloads.

## Rate-limit check priority

Stable priority order:

```text
global
source_key
actor_id_hash
region_code
source_type
```

If multiple dimensions are exceeded, the response should report the first exceeded dimension in this order.

## Rate-limit window model

Each rate-limit record is keyed by:

```text
scope + scope_key + window_start_at
```

Table:

```text
source_health_poll_rate_limits
```

Runtime may read/write only bounded columns:

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
```

## Suggested initial limits

Suggested default values for the first runtime implementation:

```text
global -> 100 requests per 60 seconds
source_key -> 5 requests per 60 seconds
actor_id_hash -> 10 requests per 60 seconds
```

These values are intentionally conservative placeholders and should be locked by tests in the implementation PR.

## Allowed statuses

Allowed rate-limit statuses:

```text
allowed
rate_limited_global
rate_limited_source
rate_limited_actor
rate_limited_region
rate_limited_source_type
```

First implementation may only use:

```text
allowed
rate_limited_global
rate_limited_source
rate_limited_actor
```

## Runtime ordering

Rate-limit runtime should run in this order:

```text
1. source lookup
2. authorization check
3. idempotency_key_hash presence check
4. active idempotency lookup
5. if reused -> return reused without rate-limit increment
6. if no active idempotency record -> check rate limits
7. if rate-limited -> return bounded 429 and do not create accepted idempotency record
8. if allowed -> create accepted idempotency record with rate_limit_status=allowed
9. proceed to existing poll execution only after idempotency and rate-limit gates pass
```

Reused idempotency requests should not increment rate-limit counters.

Missing-key, forbidden, and unknown-source requests should not increment rate-limit counters.

## Bounded allowed path

If all checked dimensions are under limit:

```text
rate_limit_status=allowed
```

Then accepted idempotency record may be created:

```text
status=accepted
rate_limit_status=allowed
```

The request may then proceed to the existing poll execution path.

This design does not approve or modify what the existing poll execution does after that point.

## Bounded rate-limited path

If a checked dimension exceeds its limit:

```text
429
error.code=rate_limited
error.message=source poll rate limited
rate_limit_status=<bounded_status>
```

Examples:

```text
rate_limited_global
rate_limited_source
rate_limited_actor
```

Rate-limited response must not include:

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

These fields must not influence rate-limit decisions:

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

If present, future implementation should ignore them for rate-limit purposes or reject with a bounded invalid_request according to a separate request validation contract.

## Race and conflict behavior

Concurrent requests may race on rate-limit rows.

First implementation should prefer simple bounded behavior:

```text
upsert rate-limit row by scope + scope_key + window_start_at
increment request_count atomically if practical
if uniqueness conflict occurs, retry bounded update once
if retry fails, return bounded 429 or bounded 409 according to implementation contract
```

Do not return SQL errors, stack traces, or raw conflict diagnostics.

## Audit interaction

Audit runtime remains a separate gate.

When audit runtime is later approved, rate-limit outcomes should be auditable as:

```text
rate_limited
```

Audit route operation must remain:

```text
source_health:poll
```

Body overrides must not alter audit route operation.

## Test plan for future implementation

Recommended future test file:

```text
apps/backend/disclosure_api/test/source_health_poll_rate_limit_runtime_test.exs
```

Recommended tests:

```text
first accepted poll increments global source and actor counters
reused idempotency request does not increment counters
source_key limit exceeded returns bounded 429
actor_id_hash limit exceeded returns bounded 429
global limit exceeded returns bounded 429
rate-limit priority is stable when multiple dimensions are exceeded
missing-key request does not increment counters
forbidden request does not increment counters
unknown-source request does not increment counters
body override cannot alter rate-limit decision
rate-limited response has no raw/private/canonical material
rate-limited response does not expose provider/materializer/canonical controls
```

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_rate_limit_runtime_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before rate-limit runtime work:

```text
104 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future rate-limit runtime work:

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

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_rate_limit_runtime_flow_design.md
```

No Codex test command is required for this docs-only design PR.
