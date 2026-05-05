# Source Health Poll Route Gated Stream Design

This document designs a gated stream for the existing source poll route after the source health backend, UI, operator smoke, and monitoring tracks have been closed out.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c8362a83fbffc37290fe096e430be09c04c730a3
base source: PR #244 Add source health monitoring final close-out
stream: source health poll route gated stream design
status: docs-only design
```

## Existing route

The existing route is:

```text
POST /api/admin/sources/:source_key/poll
```

Current router target:

```text
DisclosureAutomationWeb.AdminSourcePollController.create/2
```

Current controller path:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Current adjacent bounded unknown-source coverage exists in:

```text
apps/backend/disclosure_api/test/source_health_route_target_test.exs
```

Current bounded unknown-source expectation:

```text
404
error.code=not_found
error.message=source not found
```

## Why poll must be gated

Poll is higher risk than source health recheck.

Source health recheck is bounded to the health_checks path and does not directly approve provider fetch, materializer execution, canonical mutation, or public response changes.

Poll may be connected to source runtime behavior and currently accepts runtime-impacting parameters such as:

```text
edition
use_live_fetch
inline_feed
```

Therefore poll must not be exposed through the internal UI or expanded operationally until explicit gates are designed and tested.

## Design goal

Create a safe gated path for future poll route work without changing current behavior in this design PR.

The future poll stream must define and test:

```text
route target lock
authorization model
idempotency or dedupe model
rate limit model
bounded request payload
bounded response shape
redaction requirements
audit requirements
provider behavior boundary
materializer behavior boundary
canonical mutation boundary
public API/feed impact boundary
operator UI exposure policy
rollback and stop conditions
```

## Non-goals

This design does not implement:

```text
poll authorization
poll idempotency
poll audit storage
poll audit runtime writes
poll rate limits
poll UI
poll buttons
poll dashboard actions
new routes
route removals
provider client changes
materializer changes
canonical mutation changes
public API/feed changes
runtime metric emission
```

## Current source health UI lock remains

The internal source health UI must continue not to expose poll UI.

Forbidden UI routes remain:

```text
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
```

Forbidden UI controls remain:

```text
poll_action=enabled
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

The internal UI may continue to show:

```text
poll_action=not_rendered
```

## Proposed future phase 1: route and behavior characterization tests

Recommended next implementation PR:

```text
Add source health poll route gated characterization tests
```

Recommended test file:

```text
apps/backend/disclosure_api/test/source_health_poll_route_gated_characterization_test.exs
```

Recommended coverage:

```text
POST /api/admin/sources/:source_key/poll route target remains AdminSourcePollController.create/2
unknown source returns bounded 404
response does not expose raw/private/canonical material
route remains separate from /api/admin/source-health/:source_key/recheck
no internal UI poll route exists
no public poll route exists
```

This phase should not change runtime behavior.

## Proposed future phase 2: authorization design and tests

Poll must have a distinct permission from source health recheck.

Candidate permission:

```text
source_health:poll
```

Do not reuse:

```text
source_health:read
source_health:recheck
```

Future locked behavior should be:

```text
source_health:read -> cannot poll
source_health:recheck -> cannot poll
source_health:poll -> may poll only if all other gates pass
unknown source -> bounded 404 before or independent of authorization leakage
```

Recommended tests:

```text
read-only actor cannot poll existing source
recheck-only actor cannot poll existing source
poll actor can reach bounded poll path for existing source only after gates are explicitly approved
unknown source remains bounded 404
operation/body overrides cannot bypass authorization
```

## Proposed future phase 3: bounded request payload

Approved poll request fields must be explicitly allowlisted.

Candidate bounded operator context fields:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Candidate poll fields requiring explicit design before approval:

```text
edition
use_live_fetch
inline_feed
```

Before approving these fields, define:

```text
allowed edition values
default edition
whether use_live_fetch is allowed operationally
whether inline_feed is allowed operationally
who can set each field
how each field is audited
how each field affects public response risk
```

Request body must not accept generic control fields:

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
```

## Proposed future phase 4: idempotency and rate limits

Poll needs stronger replay and rate controls than recheck.

Future design should define:

```text
source_key + idempotency_key_hash dedupe window
source_key rate limit window
actor_id_hash rate limit window
global poll concurrency cap
poll retry policy
expired idempotency cleanup
operator visible reused/denied messages
```

Candidate idempotency statuses:

```text
accepted
reused
rate_limited
untracked_denied
```

Unlike recheck, missing idempotency for poll should be considered for denial rather than compatibility acceptance unless a separate explicit exception is approved.

## Proposed future phase 5: audit storage and runtime writes

Poll must have bounded audit storage before routine operation.

Audit event outcomes should include:

```text
accepted
reused
rate_limited
forbidden
not_found
rejected_invalid_request
failed
```

Audit route operation should be fixed:

```text
source_health:poll
```

Request body must not be able to override audit route operation.

Audit storage must not include:

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

## Proposed future phase 6: provider/materializer/canonical impact boundary

Before poll is approved operationally, document and test whether poll may trigger:

```text
external provider calls
source materialization
overlay materialization
canonical materialization
canonical feed item mutation
public feed rebuild
```

Each behavior must be classified as one of:

```text
not_called
stubbed_only
queued_async
called_inline
forbidden
```

Default safe target for first gated poll track:

```text
external provider calls -> forbidden or stubbed_only
materializer execution -> forbidden
canonical mutation -> forbidden
public feed rebuild -> forbidden
```

Any deviation requires a separate explicit design and regression suite.

## Proposed future phase 7: bounded response shape

Future poll response must be bounded.

Allowed response categories:

```text
accepted bounded poll request
reused idempotent request
rate_limited denial
forbidden denial
not_found denial
invalid_request denial
```

Response must not expose:

```text
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

## Proposed future phase 8: operator UI exposure policy

Poll UI remains forbidden until all backend gates are locked.

Do not expose in UI until:

```text
authorization tests pass
idempotency/rate-limit tests pass
audit storage/runtime tests pass
provider/materializer/canonical impact tests pass
bounded response tests pass
operator runbook is updated
operator smoke tests cover poll disabled/enabled states
```

Initial UI policy should remain:

```text
poll_action=not_rendered
```

## Public API/feed guardrails

Poll gated stream must not change public API/feed response shapes without explicit approval.

Guarded surfaces:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
public API envelope
public feed envelope
feed ordering
feed item_count
official TDnet fields
official citations
```

## Redaction and forbidden material lock

All future poll tests must deny:

```text
raw_provider_payload
full_article_text
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
provider_credentials
headers
cookies
tokens
audit_event
audit_event_id
```

## Recommended validation sequence

Future phase 1 focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_route_gated_characterization_test.exs
```

Future adjacent regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known source health adjacent result before poll work:

```text
75 tests, 0 failures
```

## Recommended next PR

Recommended next PR:

```text
Add source health poll route gated characterization tests
```

Recommended scope:

```text
test-only
route target lock
bounded unknown-source response
no internal UI poll route
no public poll route
no raw/private/canonical exposure
no provider/materializer/canonical behavior changes
no runtime poll behavior changes
```

## Stop conditions

Stop and re-scope if future poll work:

```text
lets source_health:read trigger poll
lets source_health:recheck trigger poll
adds poll UI before backend gates are locked
allows generic operation/action/queue/worker/payload controls
allows body override to select provider/materializer/canonical behavior
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reason
stores or returns headers, cookies, tokens, provider credentials, raw provider payloads, full article text, raw transport response, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
exposes audit event IDs
changes public API/feed shapes without explicit approval
adds duplicate controller modules
calls provider clients inline without a design/test gate
triggers materializers inline without a design/test gate
mutates canonical data without a design/test gate
```

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_route_gated_stream_design.md
```

No Codex test command is required for this docs-only design PR.
