# Source Health Operator Smoke Test Design

This document designs the next source health operator smoke test after the internal UI recheck action lock and operator runbook refresh.

This PR is documentation-only. It does not add or modify tests, frontend runtime code, backend runtime code, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, monitoring behavior, or alerting behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 39ab54768d66b14d1db7209fd3a74022b02082be
base source: PR #235 Refresh source health operator runbook
stream: source health operator smoke test design
status: docs-only design
```

## Goal

Design a small operator smoke test that proves the current source health internal UI and bounded recheck backend work together without expanding scope.

The smoke test should exercise:

```text
list -> detail -> enabled recheck contract -> bounded backend recheck result
read-only detail -> disabled action -> backend 403 if attempted
unknown source detail -> not_available -> backend 404 if attempted
```

The test must also prove that unsafe controls and raw/private/canonical material remain absent.

## Non-goals

This design does not implement:

```text
new routes
new UI templates
browser automation
JavaScript behavior
full form submission behavior
poll UI
poll route execution
audit read UI
monitoring dashboards
provider calls
materializer calls
canonical mutations
public source health UI
public API/feed changes
```

## Existing locked routes

Internal UI routes:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Bounded backend route used by the UI recheck action:

```text
POST /api/admin/source-health/:source_key/recheck
```

Still gated and out of scope:

```text
POST /api/admin/sources/:source_key/poll
```

## Proposed test file

Recommended future test file:

```text
apps/backend/disclosure_api/test/source_health_operator_smoke_test.exs
```

Recommended module name:

```text
DisclosureAutomation.SourceHealthOperatorSmokeTest
```

The first implementation should use `DisclosureAutomationWeb.ConnCase` and direct route requests. It does not need external browser automation.

## Fixture setup

Create a single source registry fixture for the smoke test.

Suggested fixture fields should match existing source health UI tests:

```text
source_key=source_health_operator_smoke_fixture
display_name=Source Health Operator Smoke Fixture
source_type=api
adapter_key=test_adapter
region_code=US
discovery_mode=fixture
hydrate_mode=fixture
default_home_market_region_code=US
source_class=operator_test
default_source_tier=official
base_url=https://example.test/source-health-operator-smoke
healthcheck_url=https://example.test/source-health-operator-smoke/health
parser_key=test_parser
poll_cron=0 * * * *
coverage_tags=[source_health, operator, smoke]
active=true
config={}
health_status=unknown
```

Use a separate missing source key:

```text
source_health_operator_smoke_missing
```

## Test case 1: list shell triage

Request:

```text
GET /admin/source-health
```

Expected:

```text
200
Source health
fields=source_key,display_name,source_type,region_code,health_status,last_success_at,last_failure_at,active
source_key=source_health_operator_smoke_fixture
display_name=Source Health Operator Smoke Fixture
health_status=unknown
recheck_action=not_rendered
poll_action=not_rendered
audit_ui=not_rendered
```

Must not show:

```text
button
POST /api/admin/source-health
POST /api/admin/sources
poll_source
audit_event
audit_event_id
raw/private/canonical material
```

## Test case 2: enabled detail advertises bounded recheck contract

Request:

```text
GET /admin/source-health/source_health_operator_smoke_fixture?actor_permissions=source_health:recheck
```

Expected:

```text
200
Source health detail
state=found
source_key=source_health_operator_smoke_fixture
recheck_action=enabled
recheck_method=POST
recheck_target=/api/admin/source-health/source_health_operator_smoke_fixture/recheck
idempotency=required
recheck_context=bounded
```

Expected bounded context fields:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Must not show:

```text
operation
action_operation
route_operation
queue=
worker=
payload=
provider_fetch
materialize
canonicalize
poll
audit_event
audit_event_id
raw/private/canonical material
```

## Test case 3: enabled operator can submit bounded recheck

Request:

```text
POST /api/admin/source-health/source_health_operator_smoke_fixture/recheck
```

Payload:

```text
actor_id_hash=sha256:operator-smoke-001
actor_permissions=[source_health:recheck]
request_id_hash=sha256:request-smoke-001
idempotency_key_hash=sha256:idempotency-smoke-001
reason_redacted=REDACTED_SOURCE_HEALTH_REASON
redaction_status=passed
created_at=2026-05-04T00:00:00Z
```

Expected:

```text
202
source_key=source_health_operator_smoke_fixture
queue=health_checks
idempotency_status in [accepted, reused]
```

The response may include the existing bounded accepted job shape, but must not expose raw/private/canonical material.

Must not include:

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
audit_event
audit_event_id
```

## Test case 4: read-only detail disables recheck

Request:

```text
GET /admin/source-health/source_health_operator_smoke_fixture?actor_permissions=source_health:read
```

Expected:

```text
200
Source health detail
state=found
source_key=source_health_operator_smoke_fixture
recheck_action=disabled
recheck_reason=read_only
```

Must not show:

```text
recheck_action=enabled
recheck_target=
recheck_method=POST
button
poll
audit_ui
audit_event
audit_event_id
raw/private/canonical material
```

## Test case 5: read-only backend attempt returns bounded 403

Even though the UI disables the action, the smoke test should prove the backend boundary too.

Request:

```text
POST /api/admin/source-health/source_health_operator_smoke_fixture/recheck
```

Payload:

```text
actor_id_hash=sha256:operator-smoke-read-only-001
actor_permissions=[source_health:read]
request_id_hash=sha256:request-smoke-read-only-001
idempotency_key_hash=sha256:idempotency-smoke-read-only-001
reason_redacted=REDACTED_SOURCE_HEALTH_REASON
redaction_status=passed
created_at=2026-05-04T00:00:00Z
```

Expected:

```text
403
error.code=forbidden
error.message=source health recheck not allowed
```

Must not include accepted job fields:

```text
job_id
queue
args
worker
accepted
scheduled_at
```

Must not expose raw/private/canonical material.

## Test case 6: unknown source detail and backend attempt stay bounded

Detail request:

```text
GET /admin/source-health/source_health_operator_smoke_missing?actor_permissions=source_health:recheck
```

Expected detail response:

```text
404
Source health detail
state=not_found
source_key=source_health_operator_smoke_missing
recheck_action=not_available
back=/admin/source-health
```

Must not show:

```text
recheck_action=enabled
recheck_target=
```

Backend request:

```text
POST /api/admin/source-health/source_health_operator_smoke_missing/recheck
```

Expected backend response:

```text
404
error.code=not_found
error.message=source not found
```

Must not include accepted job fields or raw/private/canonical material.

## Shared forbidden material helper

The test should reuse a single denylist helper for UI text and JSON response inspection.

Recommended denylist:

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

## Route inventory guardrail

The smoke test should not add route definitions.

The existing route inventory test already locks:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Do not add:

```text
/admin/source-health/:source_key/recheck
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
/source-health
/public/source-health
/api/public/source-health
/api/source-health
```

## Poll remains out of scope

The smoke test must not call:

```text
POST /api/admin/sources/:source_key/poll
```

The smoke test must not display or assert poll action controls except as absent controls.

Forbidden poll-related strings:

```text
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

## Audit UI remains out of scope

The smoke test must not add audit UI or audit read behavior.

Forbidden audit display strings:

```text
audit_event
audit_event_id
```

Internal audit writes for backend recheck remain part of the backend contract and should not alter the HTTP response shape.

## Expected validation command for implementation PR

When implemented, recommended focused command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_operator_smoke_test.exs
```

Recommended adjacent regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected implementation-time result target:

```text
focused smoke test: 6 tests, 0 failures
adjacent source health/UI regression: previous 55 tests + smoke tests, 0 failures
```

## Stop conditions

Stop and re-scope if implementation requires:

```text
new routes
runtime behavior changes
backend response shape changes
poll route calls
poll UI
audit read UI
provider client calls
materializer behavior
canonical mutation behavior
public API/feed behavior changes
raw/private/canonical material exposure
duplicate controller modules
```

## Recommended next PR

Recommended next PR:

```text
Add source health operator smoke test
```

Recommended scope:

```text
add apps/backend/disclosure_api/test/source_health_operator_smoke_test.exs only if possible
ConnCase direct route smoke test
6 tests based on this design
no router changes
no controller changes unless test reveals a genuine bounded marker mismatch
no poll route calls
no audit UI
no raw/private/canonical exposure
```

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_operator_smoke_test_design.md
```

No Codex test command is required for this docs-only design PR.
