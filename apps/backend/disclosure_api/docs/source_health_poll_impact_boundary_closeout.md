# Source Health Poll Impact Boundary Close-out

This document closes out the source health poll provider/materializer/canonical impact boundary test track.

This close-out PR is documentation-only. It does not add or modify runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, poll behavior, provider behavior, materializer behavior, canonical mutation behavior, audit runtime behavior, public API/feed behavior, monitoring behavior, dashboards, alerts, log sinks, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b3ce6fec26dd7c9d9de10beeb9d8a42fc79caa40
base source: PR #267 Add source health poll impact boundary tests
stream: source health poll impact boundary close-out
status: docs-only
```

## Scope closed by PR #267

PR #267 added test-only source health poll impact boundary coverage.

Closed behavior:

```text
accepted poll gate response remains bounded before downstream execution
reused response does not expose downstream controls
missing-key response does not expose downstream controls
rate-limited response does not expose downstream controls
unknown-source response does not expose downstream controls
body override fields cannot select provider/materializer/canonical behavior on bounded paths
internal source health UI still does not expose poll controls
internal source health poll UI routes remain absent
public source health poll UI routes remain absent
public API/feed route inventory remains separate from source health poll
```

Test file from PR #267:

```text
apps/backend/disclosure_api/test/source_health_poll_impact_boundary_test.exs
```

## Explicit non-goals

PR #267 and this close-out do not implement:

```text
new runtime behavior
new route behavior
new controller behavior
new migrations
backend response shape changes
poll UI
provider behavior changes
materializer behavior changes
canonical behavior changes
public API/feed behavior changes
monitoring/dashboard/alert changes
```

## Downstream control lock

Bounded poll responses must not expose or accept downstream behavior controls on bounded paths:

```text
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
canonical_mutation
canonical_payload
```

Generic override fields must not select downstream behavior:

```text
operation
action_operation
route_operation
action
queue
worker
payload
```

## UI route lock

Forbidden internal UI routes remain absent:

```text
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
```

Forbidden public/source health poll routes remain absent:

```text
/source-health/:source_key/poll
/public/source-health/:source_key/poll
/api/public/source-health/:source_key/poll
/api/source-health/:source_key/poll
```

Internal source health UI still does not expose:

```text
poll_action=enabled
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

## Public API/feed route lock

Public API/feed routes remain separate from source health poll:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
```

Source health poll work must not create public poll routes such as:

```text
POST /api/feed/poll
POST /api/events/:event_id/poll
```

## Redaction lock

Bounded poll paths must not expose:

```text
raw_provider_payload
full_article_text
raw_transport_response
sql_details
stack_trace
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

## Validation evidence

PR #267 validation:

```text
focused poll impact boundary test: 8 tests, 0 failures
adjacent source health/UI/monitoring/poll regression: 139 tests, 0 failures
```

Validated cases:

```text
accepted poll gate response bounded before downstream execution
reused/missing-key/rate-limited/unknown-source responses do not expose downstream controls
body override fields cannot select provider/materializer/canonical behavior on bounded paths
internal source health UI still does not expose poll controls
internal/public source health poll UI routes remain absent
public API/feed route inventory remains separate from source health poll
```

Known unrelated warnings remain:

```text
Phoenix.ConnTest deprecation warning
FeedController unreachable clause warning
existing compile/type warnings
```

## Recommended final impact boundary regression command

Focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_impact_boundary_test.exs
```

Adjacent command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_impact_boundary_test.exs test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
139 tests, 0 failures
```

## Remaining work after this close-out

Recommended next PR:

```text
Add source health poll final close-out
```

Recommended scope:

```text
docs-only final close-out
route/authorization/idempotency/rate-limit/audit/impact boundary summary
latest validation evidence
remaining future work, if any
no runtime changes
```

Alternative if product needs operator-facing poll documentation before final close-out:

```text
Add source health poll operator runbook
```

Only choose operator runbook if poll operation will be exposed to operators.

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

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_impact_boundary_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
