# Source Health Poll Provider, Materializer, and Canonical Impact Boundary

This document defines the provider/materializer/canonical impact boundary for the source health poll gated stream.

This PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 7ee6a6e7366a8ce025fce4b0af31485fbebd1e77
base source: PR #265 Add source health poll audit runtime close-out
stream: source health poll provider/materializer/canonical impact boundary
status: docs-only design
```

## Existing locked prerequisites

The source health poll stream now has these backend gates:

```text
route characterization
authorization gate: source_health:poll
idempotency storage and runtime gate
rate-limit storage and runtime gate
audit storage and runtime writes
```

Existing route:

```text
POST /api/admin/sources/:source_key/poll
```

Current accepted path still reaches the existing poll execution path after all gates pass.

## Goal

Define what a source health poll request is allowed to affect after it passes authorization, idempotency, rate-limit, and audit gates.

This boundary prevents poll work from silently expanding into provider fetch, materializer execution, canonical mutation, or public API/feed changes without explicit design and tests.

## Classification model

Every downstream behavior must be classified before any future poll work changes it.

Allowed classifications:

```text
forbidden
not_called
stubbed_only
queued_async
called_inline
```

Default safe classification for the current boundary:

```text
external provider calls -> existing behavior only, no expansion
source materialization -> no expansion
overlay materialization -> no expansion
canonical materialization -> forbidden without separate gate
canonical mutation -> forbidden without separate gate
public feed rebuild -> forbidden without separate gate
public API/feed response shape change -> forbidden without separate gate
```

## Provider boundary

Provider behavior includes:

```text
external provider HTTP calls
provider API clients
live fetch flags
transport response handling
provider credentials
raw provider payload storage
```

Current boundary:

```text
no new provider clients
no new provider endpoints
no new provider credentials
no raw provider payload exposure
no raw transport response exposure
no new live fetch controls in source health UI
```

Fields requiring explicit gate before operational exposure:

```text
use_live_fetch
provider_fetch
```

If a future PR changes provider behavior, it must define:

```text
which provider is called
whether call is inline or queued
timeout behavior
retry behavior
credential access pattern
redaction policy
raw payload storage policy
operator-visible response shape
public API/feed impact
rollback plan
```

## Materializer boundary

Materializer behavior includes:

```text
source materialization
overlay materialization
canonical materialization
inline feed rebuild
scheduler enqueueing of materializer jobs
```

Current boundary:

```text
no new materializer execution from source health poll
no new inline materializer calls
no new materializer queue controls
no new materializer payload controls
```

Fields requiring explicit gate before operational exposure:

```text
materialize
inline_feed
queue
worker
payload
```

If a future PR changes materializer behavior, it must define:

```text
which materializer runs
whether it is inline or queued
queue name
worker name
allowed payload shape
idempotency behavior
rate-limit behavior
audit behavior
public API/feed impact
rollback plan
```

## Canonical boundary

Canonical behavior includes:

```text
canonical event mutation
canonical feed item mutation
canonical citation mutation
canonical fact override mutation
canonical merge behavior
public feed ordering changes
public feed item_count changes
```

Current boundary:

```text
canonical mutation is forbidden without a separate canonical impact gate
source health poll accepted does not approve canonical mutation
source health poll audit accepted does not approve canonical mutation
source health poll rate-limit allowed does not approve canonical mutation
```

Fields requiring explicit gate before operational exposure:

```text
canonicalize
canonical_mutation
canonical_payload
```

If a future PR changes canonical behavior, it must define:

```text
exact canonical tables affected
mutation type
merge policy
official TDnet precedence policy
citation policy
rollback behavior
public API/feed response impact
regression suite
```

## Public API/feed boundary

Guarded public surfaces:

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

Current boundary:

```text
source health poll gates must not change public API/feed response shapes
source health poll gates must not change public feed ordering
source health poll gates must not change public feed item_count
source health poll gates must not override official TDnet facts
source health poll gates must not override official citations
```

Any future public API/feed impact must have a dedicated design and regression PR.

## UI exposure boundary

Poll UI remains out of scope until all backend downstream impact gates are explicit.

Still forbidden in internal UI:

```text
poll_action=enabled
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

Forbidden UI routes remain:

```text
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
```

## Request body override boundary

Request body must not select downstream behavior through generic controls:

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
canonical_mutation
canonical_payload
```

Server-side gates must derive behavior from locked backend contracts, not request body override fields.

## Audit and monitoring boundary

Audit runtime records bounded poll outcomes only.

Audit accepted does not mean:

```text
provider fetch succeeded
materializer ran
canonical mutation occurred
public feed changed
```

Monitoring should treat poll outcome states separately from provider/materializer/canonical outcomes unless later gates explicitly connect them.

## Redaction boundary

Future provider/materializer/canonical impact work must not expose:

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
audit_event_id
```

## Recommended future test file

Recommended next test file:

```text
apps/backend/disclosure_api/test/source_health_poll_impact_boundary_test.exs
```

Recommended tests:

```text
accepted poll bounded gates do not expose provider/materializer/canonical controls in responses
request body override cannot select provider/materializer/canonical behavior on bounded deny paths
source health internal UI still does not expose poll controls
public source health poll routes remain absent
public API/feed response shape contract remains unchanged by poll gate tests
canonical mutation terms remain absent from bounded poll responses
```

This test PR should be characterization-only unless a later design explicitly changes downstream behavior.

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_impact_boundary_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_impact_boundary_test.exs test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before impact boundary tests:

```text
131 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future work:

```text
lets request body override provider/materializer/canonical behavior
adds poll UI before downstream impact gates are locked
changes public API/feed response shapes without explicit design and regression
mutates canonical data without explicit canonical impact design
stores or returns raw provider payloads
stores or returns raw transport responses
stores or returns canonical payloads
stores or returns full article text
stores or returns provider credentials, headers, cookies, or tokens
exposes audit event IDs in HTTP responses
adds duplicate controller modules
```

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_provider_materializer_canonical_impact_boundary.md
```

No Codex test command is required for this docs-only design PR.
