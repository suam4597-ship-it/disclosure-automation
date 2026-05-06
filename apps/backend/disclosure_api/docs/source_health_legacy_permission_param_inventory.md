# Source Health Legacy Permission Param Inventory

This document inventories the remaining Source Health `actor_permissions` request-param compatibility surfaces after the first SourceHealthAuthContext migration pass.

This PR is documentation-only. It does not remove fallback behavior, change runtime authorization behavior, change routes, change response shapes, add UI surfaces, add migrations, or change provider/materializer/canonical behavior.

## Baseline

```text
base branch: chatgpt-source-health-operator-smoke-auth-context-v1
base source: PR #283 Use auth context in source health operator smoke test
stream: source health production auth/session replacement
status: docs-only inventory
```

## Why this inventory exists

The fast MVP direction now keeps the existing public HTML shell and exposes only the bounded Source Health operator surface. Production auth/session hardening remains active only where it protects that operator surface.

Recent completed auth-context migration work:

```text
PR #273 SourceHealthAuthContext helper
PR #274 auth context bridge into recheck/poll authorization plugs
PR #275 recheck authorization tests migrated to SourceHealthAuthContext
PR #276 poll authorization tests migrated to SourceHealthAuthContext
PR #281 internal UI recheck action migrated to SourceHealthAuthContext
PR #282 internal UI recheck submit-flow tests migrated to SourceHealthAuthContext
PR #283 operator smoke test migrated to SourceHealthAuthContext
```

The next safe step is not to remove fallback abruptly. The next safe step is to inventory exactly where legacy request-param compatibility remains so the future production-mode denial/removal PR can be small and reviewable.

## Current rule

Current source health authorization behavior should be understood as:

```text
if explicit SourceHealthAuthContext is available:
  use SourceHealthAuthContext as the authority
else:
  allow temporary legacy actor_permissions request-param fallback
```

The fallback exists for compatibility only. It is not the desired final production authorization model.

## Remaining runtime compatibility surfaces

### 1. Internal Source Health UI recheck action state

File:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_ui_controller.ex
```

Current compatibility behavior:

```text
permission_state_requested?/2 returns true when SourceHealthAuthContext is available
or when params contains actor_permissions.

actor_permissions/2 prefers SourceHealthAuthContext when available.
If no auth context is available, it falls back to request_param_actor_permissions/1.
```

Current risk:

```text
In non-test runtime, if no production auth context has been injected yet, query-string actor_permissions can still request UI recheck action state.
```

Current mitigation already locked:

```text
When explicit SourceHealthAuthContext is present, query actor_permissions cannot override it.
```

Future target:

```text
Production mode must not allow query-string actor_permissions to drive UI action state.
Fallback should be gated to explicit test harness mode or removed after production auth injection is complete.
```

### 2. Source Health recheck authorization fallback

File:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_recheck_authorization.ex
```

Current compatibility behavior:

```text
recheck_allowed?/1 prefers SourceHealthAuthContext when available.
If no auth context is available, it falls back to recheck_allowed_from_params?/1.

recheck_allowed_from_params?/1 checks params["actor_permissions"] for source_health:recheck.

auth_params/1 prefers SourceHealthAuthContext when available.
If no auth context is available, it falls back to conn.params for audit context.
```

Current risk:

```text
In non-test runtime, if no production auth context has been injected yet, body/query actor_permissions can still authorize source health recheck.
Audit context may also derive from request params when no auth context is present.
```

Current mitigation already locked:

```text
When explicit SourceHealthAuthContext is present, request body actor_permissions cannot override it.
Focused authorization, submit-flow, and operator smoke tests now cover this behavior.
```

Future target:

```text
Production mode must deny request-param actor_permissions authority.
Audit writers should use server-derived SourceHealthAuthContext values in production.
Legacy fallback should be gated to explicit test harness mode or removed after production auth injection is complete.
```

### 3. Source Health poll authorization fallback

File:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_poll_authorization.ex
```

Current compatibility behavior:

```text
poll_allowed?/1 prefers SourceHealthAuthContext when available.
If no auth context is available, it falls back to poll_allowed_from_params?/1.

poll_allowed_from_params?/1 checks params["actor_permissions"] for source_health:poll.

auth_params/1 prefers SourceHealthAuthContext when available.
If no auth context is available, it falls back to conn.params for audit context.
```

Current risk:

```text
In non-test runtime, if no production auth context has been injected yet, body/query actor_permissions can still authorize source health poll.
Audit context may also derive from request params when no auth context is present.
```

Current mitigation already locked:

```text
When explicit SourceHealthAuthContext is present, request-param escalation cannot override it.
Poll authorization tests were migrated to SourceHealthAuthContext in PR #276.
```

Future target:

```text
Production mode must deny request-param actor_permissions authority for poll.
Poll audit context should derive from server auth context in production.
Legacy fallback should be gated to explicit test harness mode or removed after production auth injection is complete.
```

## Known test surfaces already migrated away from direct authority

The following focused surfaces now use SourceHealthAuthContext as the primary test harness:

```text
apps/backend/disclosure_api/test/source_health_recheck_authorization_test.exs
apps/backend/disclosure_api/test/source_health_poll_authorization_contract_test.exs
apps/backend/disclosure_api/test/source_health_internal_ui_recheck_action_test.exs
apps/backend/disclosure_api/test/source_health_internal_ui_recheck_submit_flow_test.exs
apps/backend/disclosure_api/test/source_health_operator_smoke_test.exs
```

These tests may still include escalation attempts, but those attempts are now expected to fail when an explicit auth context is present.

## Compatibility fallback classification

```text
Allowed for now:
  legacy fallback when no SourceHealthAuthContext is present

Allowed as test coverage:
  request-param/body escalation attempts that prove explicit auth context wins

Not allowed as final production behavior:
  request body actor_permissions granting source_health:recheck or source_health:poll
  query string actor_permissions granting source health UI action state
  request params supplying raw/private auth or audit material
```

## Recommended next PR

Recommended next PR:

```text
Design source health production-mode permission param denial
```

Suggested scope:

```text
docs-only or focused contract-test first
explicit production-mode behavior definition
request-param actor_permissions denied or ignored outside explicit test harness
SourceHealthAuthContext remains the only accepted bounded authority when present
no route changes
no response shape changes unless explicitly contracted
no poll UI
audit UI remains absent
public Source Health UI remains absent
```

## Do not do in the next PR

```text
do not remove all fallback abruptly
do not add production session integration in the same PR
do not add poll UI
do not add audit UI
do not add public Source Health UI
do not change provider/materializer/canonical behavior
do not change public API/feed response shapes
```

## Fast MVP drift check

- [x] Keeps existing HTML/CSS shell unchanged.
- [x] Does not introduce React/Vue/Next.js or another frontend framework.
- [x] Uses existing backend routes; adds no routes.
- [x] Does not add poll UI.
- [x] Does not add audit UI.
- [x] Does not add public Source Health UI.
- [x] Does not change provider/materializer/canonical behavior.
- [x] Does not change backend response shapes.
- [x] Keeps Source Health auth/session work limited to operator protection.
- [x] Updates workflow state by defining the next auth hardening PR.

## Validation

This inventory PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_legacy_permission_param_inventory.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
