# Source Health Poll Idempotency and Rate Limit Contract

This document defines the idempotency and rate-limit contract for the future source health poll gated stream.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit storage/runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 9404c56bbf45585b46f3bc6cb41ba393610d4c4e
base source: PR #248 Add source health poll authorization contract tests
stream: source health poll idempotency and rate-limit contract
status: docs-only contract
```

## Existing gated route

Existing poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Existing target:

```text
DisclosureAutomationWeb.AdminSourcePollController.create/2
```

Authorization gate now requires:

```text
source_health:poll
```

This contract does not change route target, authorization, or poll runtime behavior.

## Goal

Define the future idempotency and rate-limit requirements before poll becomes routine operational behavior.

Poll is higher risk than source health recheck because it may affect source runtime behavior. Therefore poll should have stricter idempotency and rate-limit behavior than recheck.

## Non-goals

This contract does not implement:

```text
poll idempotency storage
poll idempotency runtime dedupe
poll rate-limit storage
poll rate-limit runtime enforcement
poll audit storage
poll audit runtime writes
provider behavior changes
materializer behavior changes
canonical mutation changes
public API/feed changes
operator UI poll controls
```

## Required bounded request context

Future poll idempotency/rate-limit checks may consume only bounded context:

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

Do not require or persist:

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
```

## Idempotency key requirement

Poll should require a bounded idempotency key hash.

Future behavior should prefer:

```text
missing idempotency_key_hash -> bounded 400 or 409 denial
empty idempotency_key_hash -> bounded 400 or 409 denial
source_key + idempotency_key_hash duplicate inside window -> reused
source_key + idempotency_key_hash first seen inside window -> accepted if rate limits also pass
```

Unlike source health recheck, poll should not default to `untracked` acceptance unless a separate compatibility exception is explicitly approved.

## Candidate idempotency statuses

Approved future statuses:

```text
accepted
reused
missing_key_denied
expired
```

Optional status if a compatibility exception is later approved:

```text
untracked_denied
```

Not approved:

```text
untracked accepted poll
raw idempotency key response
idempotency record ID response
```

## Candidate rate-limit dimensions

Poll should define bounded rate limits across multiple dimensions.

Candidate dimensions:

```text
source_key
actor_id_hash
global
region_code
source_type
```

Required first implementation dimensions:

```text
source_key
actor_id_hash
global
```

Rate-limit checks must not require raw actor IDs, raw request IDs, raw idempotency keys, headers, cookies, tokens, or provider credentials.

## Candidate rate-limit statuses

Approved future statuses:

```text
allowed
rate_limited_source
rate_limited_actor
rate_limited_global
rate_limited_region
rate_limited_source_type
```

If multiple limits are exceeded, response should choose a stable bounded priority order.

Suggested priority:

```text
global
source_key
actor_id_hash
region_code
source_type
```

## Bounded response contract

Future accepted response category:

```text
202
poll_status=accepted
idempotency_status=accepted
rate_limit_status=allowed
source_key=<source_key>
```

Future reused response category:

```text
202 or 200
poll_status=reused
idempotency_status=reused
rate_limit_status=allowed
source_key=<source_key>
```

Future missing-key denial category:

```text
400 or 409
error.code=missing_idempotency_key
error.message=poll idempotency key required
```

Future rate-limit denial category:

```text
429
error.code=rate_limited
error.message=source poll rate limited
rate_limit_status=<bounded_status>
```

Response must not include:

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

## Storage contract requirements

If storage is added, use dedicated poll tables. Do not reuse source health recheck tables.

Candidate idempotency table:

```text
source_health_poll_idempotency_keys
```

Candidate rate-limit table or aggregate source:

```text
source_health_poll_rate_limits
```

Storage may include bounded columns only:

```text
source_key
actor_id_hash
request_id_hash
idempotency_key_hash
status
rate_limit_status
expires_at
last_seen_at
metadata
inserted_at
updated_at
```

Storage must not include raw/private/canonical columns.

## Audit interaction

Future poll idempotency/rate-limit outcomes should be auditable.

Candidate audit result statuses:

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

Audit route operation should remain fixed:

```text
source_health:poll
```

Body overrides must not alter audit route operation.

## Body override prevention

These fields must not select idempotency, rate-limit, provider, materializer, or canonical behavior:

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

If present, they must be ignored or rejected according to a future bounded request contract.

## Provider/materializer/canonical boundary

Idempotency and rate-limit work must not approve provider, materializer, or canonical behavior by itself.

Still requires separate gates:

```text
provider behavior gate
materializer behavior gate
canonical mutation gate
public API/feed impact gate
```

Default safe interpretation for this contract:

```text
idempotency accepted does not mean provider fetch approved
rate-limit allowed does not mean materializer execution approved
poll accepted does not mean canonical mutation approved
```

## UI policy

Poll UI remains not rendered until idempotency and rate-limit behavior is locked and all other poll gates are approved.

Still forbidden:

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
apps/backend/disclosure_api/test/source_health_poll_idempotency_rate_limit_contract_test.exs
```

Recommended test cases:

```text
poll idempotency status allowlist is bounded
poll rate-limit status allowlist is bounded
poll storage contract denies raw/private/canonical columns
missing idempotency key is characterized as denied in the future contract
rate-limit response shape is bounded
body override cannot select provider/materializer/canonical behavior
```

The first implementation should be test-only or storage-contract-only.

Do not implement runtime emitters, provider calls, materializers, canonical mutations, public feed rebuilds, or UI poll controls in the first idempotency/rate-limit PR.

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_rate_limit_contract_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before idempotency/rate-limit work:

```text
86 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future poll idempotency/rate-limit work:

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

## Validation for this contract PR

This contract PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_idempotency_rate_limit_contract.md
```

No Codex test command is required for this docs-only contract PR.
