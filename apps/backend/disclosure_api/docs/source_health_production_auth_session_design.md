# Source Health Production Auth and Session Replacement Design

This document designs the production auth/session replacement for the current source health permission test harness.

This PR is documentation-only. It does not add or modify runtime code, tests, migrations, routes, controllers, templates, backend response shapes, source health behavior, recheck behavior, poll behavior, provider behavior, materializer behavior, canonical behavior, public API/feed behavior, UI behavior, monitoring, dashboards, alerts, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c72a3b1d277b5fc4f6c678c72d2c19cb82f20384
base source: PR #270 Add source health final close-out
stream: source health production auth/session replacement design
status: docs-only design
```

## Why this track is next

The current source health and poll backend gates are closed for their scoped behavior, but test and internal flows still rely on request-param permission inputs.

Current bounded permissions already used across the stream:

```text
source_health:read
source_health:recheck
source_health:poll
```

The next production hardening step is to replace request-param permission authority with a production session/role/permission source.

## Goal

Design a production-safe authorization model for source health UI, recheck, and poll flows.

The replacement must preserve all existing bounded behavior while changing the source of authority from request params to server-derived session context.

## Non-goals

This design does not implement:

```text
runtime auth/session lookup
new routes
new controllers
new migrations
new UI controls
backend response shape changes
poll behavior changes
recheck behavior changes
provider/materializer/canonical behavior changes
public API/feed changes
monitoring/dashboard/alert changes
```

## Current test harness inputs to replace

Current tests and internal harnesses may pass permissions through params such as:

```text
actor_permissions=source_health:read
actor_permissions=source_health:recheck
actor_permissions=source_health:poll
actor_permissions[]=source_health:read
actor_permissions[]=source_health:recheck
actor_permissions[]=source_health:poll
```

These must not be authoritative in production.

Future production behavior should derive permissions from:

```text
authenticated session
server-side user identity
server-side role mapping
server-side permission mapping
```

## Production permission model

Required permissions:

```text
source_health:read
source_health:recheck
source_health:poll
```

Permission meanings:

```text
source_health:read -> may view internal source health list/detail
source_health:recheck -> may submit bounded source health recheck
source_health:poll -> may submit bounded source poll after all poll gates pass
```

Non-equivalence rules:

```text
source_health:read is not enough for recheck
source_health:read is not enough for poll
source_health:recheck is not enough for poll
source_health:poll does not automatically imply source_health:recheck unless explicitly granted by role mapping
```

## Suggested role mapping

Recommended initial roles:

```text
source_health_viewer -> source_health:read
source_health_operator -> source_health:read, source_health:recheck
source_health_poll_operator -> source_health:read, source_health:poll
source_health_admin -> source_health:read, source_health:recheck, source_health:poll
```

The role names are suggestions. The important contract is the permission set.

## Session context contract

A production request should expose a bounded auth context to source health gates:

```text
actor_id_hash
actor_permissions
request_id_hash
session_id_hash
role_names
redaction_status
created_at
```

Do not expose or persist in source health responses:

```text
raw_actor_id
raw_user_id
raw_session_id
email
headers
cookies
tokens
provider_credentials
private_actor_context
```

## Server-derived actor hashes

Production auth must generate server-derived hashes for:

```text
actor_id_hash
request_id_hash
session_id_hash
```

Requirements:

```text
hashes are stable enough for audit correlation within the intended window
raw identifiers are not returned in HTTP responses
raw identifiers are not stored in source health audit tables
request body cannot override hash values
query string cannot override hash values
```

## UI authorization behavior

Internal source health UI routes:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Recommended behavior:

```text
unauthenticated -> redirect to login or bounded 401 according to app convention
authenticated without source_health:read -> bounded 403 or no page access
source_health:read -> list/detail visible
source_health:recheck without read -> no UI page access unless product policy explicitly allows implied read
source_health:poll without read -> no UI page access unless product policy explicitly allows implied read
```

The existing UI lock remains:

```text
no poll UI routes
no audit UI routes
no public source health UI routes
```

## Recheck authorization behavior

Route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Production behavior should preserve:

```text
source_health:recheck required
source_health:read alone -> bounded 403
unknown source -> bounded 404
accepted/reused/untracked response shapes unchanged
audit response shape unchanged
```

Request body must not override:

```text
actor_permissions
actor_id_hash
request_id_hash
session_id_hash
route_operation
```

## Poll authorization behavior

Route:

```text
POST /api/admin/sources/:source_key/poll
```

Production behavior should preserve:

```text
source_health:poll required
source_health:read alone -> bounded 403
source_health:recheck alone -> bounded 403
unknown source -> bounded 404
missing idempotency key -> bounded 409
rate-limited -> bounded 429
reused -> bounded 202
accepted path remains gated
```

Request body must not override:

```text
actor_permissions
actor_id_hash
request_id_hash
session_id_hash
route_operation
result_status
idempotency_status
rate_limit_status
provider/materializer/canonical controls
```

## Test harness compatibility strategy

The transition should avoid breaking existing contract tests abruptly.

Recommended phased strategy:

```text
Phase 1: introduce auth context helper with explicit test harness mode
Phase 2: update source health auth plugs to read server-derived context first
Phase 3: update tests to use helper/session setup instead of raw params
Phase 4: make request-param actor_permissions non-authoritative outside test harness
Phase 5: remove or quarantine direct request-param permission authority
```

Test harness mode must be explicit and unavailable in production config.

## Suggested helper API

Recommended helper module:

```text
DisclosureAutomationWeb.SourceHealthAuthContext
```

Recommended functions:

```text
fetch_source_health_auth_context(conn)
has_permission?(context, permission)
put_test_source_health_permissions(conn, permissions)
server_actor_id_hash(context)
server_request_id_hash(context)
```

The helper should return bounded context only.

## Audit interaction

Audit writers must use server-derived auth context values.

Audit records may include:

```text
actor_id_hash
request_id_hash
session_id_hash if a dedicated column or metadata contract is approved
actor_permissions if bounded and already approved by audit contract
```

Audit records must not include:

```text
raw_actor_id
raw_user_id
raw_session_id
email
headers
cookies
tokens
private_actor_context
```

## Response redaction lock

All existing redaction locks remain.

HTTP responses must not expose:

```text
raw_actor_id
raw_user_id
raw_session_id
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

## Recommended future test file

Recommended next test file:

```text
apps/backend/disclosure_api/test/source_health_production_auth_contract_test.exs
```

Recommended tests:

```text
unauthenticated source health UI access is denied or redirected according to app convention
authenticated user without source_health:read cannot view internal source health UI
source_health:read can view list/detail but cannot recheck or poll
source_health:recheck can recheck only when session-derived permission is present
source_health:poll can poll only when session-derived permission is present
request body actor_permissions cannot grant recheck
request body actor_permissions cannot grant poll
query string actor_permissions cannot grant UI recheck action in production mode
server-derived actor_id_hash is used for audit context
raw actor/session/request identifiers are absent from responses
```

## Validation command for future implementation PR

Focused future validation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_production_auth_contract_test.exs
```

Adjacent future regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_production_auth_contract_test.exs test/source_health_poll_impact_boundary_test.exs test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_monitoring_snapshot_test.exs test/source_health_monitoring_helpers_test.exs test/source_health_monitoring_contract_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Current known adjacent result before production auth work:

```text
139 tests, 0 failures
```

## Stop conditions

Stop and re-scope if future auth work:

```text
lets request body grant source_health:recheck or source_health:poll in production
lets query string grant source_health:recheck or source_health:poll in production
stores or returns raw actor/session/request identifiers
returns headers, cookies, tokens, provider credentials, raw payloads, canonical payloads, stack traces, SQL details, or unbounded diagnostics
changes recheck or poll response shapes without explicit contract update
adds poll UI as part of auth replacement
changes public API/feed shapes
adds duplicate controller modules
```

## Validation for this design PR

This design PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_production_auth_session_design.md
```

No test command is required for this docs-only PR.
