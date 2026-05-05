# Source Health Poll Final Close-out

This document closes out the current source health poll gated stream.

This PR is documentation-only. It does not add or modify runtime code, tests, migrations, routes, controllers, templates, backend response shapes, poll behavior, provider behavior, materializer behavior, canonical behavior, public API/feed behavior, UI behavior, monitoring, dashboards, alerts, or integrations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 14376cbf9c55238e2ab434c61865d28a16950c83
base source: PR #268 Add source health poll impact boundary close-out
stream: source health poll final close-out
status: docs-only
```

## Closed backend gates

The current poll stream closes the gated backend track for:

```text
POST /api/admin/sources/:source_key/poll
```

Closed areas:

```text
route characterization
authorization gate
idempotency storage and runtime gate
rate-limit storage and runtime gate
audit storage and runtime writes
provider/materializer/canonical impact boundary
UI/public route non-exposure boundary
```

## Locked behavior summary

```text
source_health:poll is required
source_health:read is not enough
source_health:recheck is not enough
unknown source returns bounded 404
missing or empty idempotency_key_hash returns bounded 409
repeated source_key + idempotency_key_hash returns reused without poll execution
rate limits cover global, source_key, and actor_id_hash
rate-limited requests return bounded 429
poll audit route_operation is fixed to source_health:poll
audit IDs are not returned in HTTP responses
bounded poll responses do not expose downstream provider/materializer/canonical controls
source health poll UI routes remain absent
public poll routes remain absent
```

## Storage surfaces

```text
source_health_poll_idempotency_keys
source_health_poll_rate_limits
source_health_poll_audit_events
```

These tables are bounded and must not store raw actor, request, idempotency, provider, transport, canonical, header, cookie, token, stack trace, SQL detail, or unbounded diagnostic material.

## UI and public route lock

Forbidden internal UI routes remain absent:

```text
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
```

Forbidden public/source-health poll routes remain absent:

```text
/source-health/:source_key/poll
/public/source-health/:source_key/poll
/api/public/source-health/:source_key/poll
/api/source-health/:source_key/poll
```

Public API/feed routes remain separate from source health poll.

## Validation evidence

Recent poll stream validations:

```text
PR #246 focused poll characterization: 5 tests, 0 failures
PR #248 focused poll authorization: 6 tests, 0 failures
PR #250 focused poll idempotency/rate-limit contract: 6 tests, 0 failures
PR #251 focused poll idempotency/rate-limit storage: 6 tests, 0 failures
PR #254 focused poll idempotency runtime: 6 tests, 0 failures
PR #257 focused poll rate-limit runtime: 8 tests, 0 failures
PR #260 focused poll audit contract: 7 tests, 0 failures
PR #261 focused poll audit storage: 5 tests, 0 failures
PR #264 focused poll audit runtime: 7 tests, 0 failures
PR #267 focused poll impact boundary: 8 tests, 0 failures
PR #267 adjacent source health/UI/monitoring/poll regression: 139 tests, 0 failures
```

Migration validation:

```text
PR #251 rollback/re-migrate cycle: PASS
PR #261 rollback/re-migrate cycle: PASS
```

## Recommended final regression command

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_poll_impact_boundary_test.exs test/source_health_poll_audit_runtime_test.exs test/source_health_poll_audit_storage_migration_test.exs test/source_health_poll_audit_runtime_contract_test.exs test/source_health_poll_rate_limit_runtime_test.exs test/source_health_poll_idempotency_runtime_test.exs test/source_health_poll_idempotency_rate_limit_storage_migration_test.exs test/source_health_poll_idempotency_rate_limit_contract_test.exs test/source_health_poll_authorization_contract_test.exs test/source_health_poll_route_gated_characterization_test.exs
```

## Remaining work

The backend poll gate stream is closed for the current scope.

Future work should start from a new design track if product requirements call for:

```text
operator-facing poll runbook
operator smoke tests
poll UI exposure
public API/feed impact
canonical mutation
provider/materializer expansion
```

## Stop conditions

Stop and re-scope if future work:

```text
lets request body override provider/materializer/canonical behavior
adds poll UI before product approval and operator coverage
changes public API/feed response shapes without explicit design and regression
mutates canonical data without explicit canonical impact design
stores or returns raw provider, transport, canonical, credential, header, cookie, token, full text, or unbounded diagnostic material
exposes audit event IDs in HTTP responses
adds duplicate controller modules
```

## Validation for this PR

This final close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_poll_final_closeout.md
```

No test command is required for this docs-only PR.
