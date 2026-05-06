# Source Health Production Session Source Close-out

This document closes out the Source Health production session source workset.

This PR is documentation-only. It records the locked behavior and validation evidence from the production session source design, contract tests, helper builder, and route wiring PRs.

## Baseline

```text
base branch: chatgpt-source-health-production-context-route-wire-v1
base source: PR #292 Wire production source health auth context into operator routes
stream: source health production session source
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #289 Design source health production session source
PR #290 Add source health production session source contract tests
PR #291 Add source health production auth context builder
PR #292 Wire production source health auth context into operator routes
```

## Locked production session behavior

Production Source Health auth context behavior is now locked as follows:

```text
server-derived Source Health assigns present -> SourceHealthProductionAuthContext builds SourceHealthAuthContext
SourceHealthAuthContext present -> SourceHealthAuthContext is authoritative
request params cannot override production context
production context wins over test helper context
missing production assigns with fallback disabled -> bounded denial / not_rendered behavior
unknown fallback mode remains fail-closed to :disabled from the previous workset
```

## Locked role mapping

The production role-to-permission mapping is locked as:

```text
source_health_viewer -> source_health:read
source_health_operator -> source_health:read, source_health:recheck
source_health_poll_operator -> source_health:read, source_health:poll
source_health_admin -> source_health:read, source_health:recheck, source_health:poll
```

Non-equivalence remains locked:

```text
source_health:read is not enough for recheck
source_health:read is not enough for poll
source_health:recheck is not enough for poll
source_health:poll does not automatically imply source_health:recheck unless explicitly granted by role mapping
```

## Runtime surfaces wired

The production auth context plug is:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_production_auth_context.ex
```

The plug is pass-through unless server-derived Source Health assigns are present.

Wired existing Source Health operator route surfaces:

```text
/admin/source-health
/admin/source-health/:source_key
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
/api/admin/sources/:source_key/poll
```

The workset does not add new routes.

## Non-Source Health routes remain outside the new pipeline

Duplicate-group routes remain outside the new Source Health production auth context pipeline.

This boundary is important because the plug is scoped to Source Health operator protection only and must not accidentally change unrelated admin surfaces.

## Locked route behavior

Focused route-wiring tests lock these behaviors:

```text
production operator assigns enable bounded UI recheck action
production viewer assigns keep UI recheck disabled even when query params claim recheck
production operator assigns authorize backend recheck with fallback disabled
missing production assigns deny backend recheck despite body actor_permissions
recheck-only operator does not authorize poll
poll operator passes poll authorization and reaches the existing idempotency gate
```

## Locked response and UI boundaries

This workset does not add or change:

```text
backend JSON response shapes
new routes
new controllers
new migrations
frontend static shell
login UI
poll UI
audit UI
public Source Health UI
provider behavior
materializer behavior
canonical behavior
monitoring integrations
dashboards
alerts
```

Bounded denial behavior remains existing surface-specific behavior:

```text
recheck unauthorized -> bounded 403 source health recheck not allowed
poll unauthorized -> bounded 403 source poll not allowed
unknown source -> bounded 404 source not found
poll operator with missing idempotency key -> existing bounded 409 missing_idempotency_key
```

## Validation evidence

PR #292 local validation at head:

```text
59ca2cb9d5c465060ae62e71ae47ab76c2a34c08
```

Focused validation:

```text
20 tests, 0 failures
```

Adjacent Source Health/auth/UI regression:

```text
93 tests, 0 failures
```

PR review:

```text
4235116514
```

Validation summary:

```text
diff scope: PASS, changed files were exactly the expected plug/router/test files
production route wiring: PASS
source health route scope: PASS
duplicate-group route impact: PASS
production operator UI: PASS
production viewer UI: PASS
backend recheck: PASS
missing assigns denial: PASS
poll authorization/idempotency gate boundary: PASS
route/response shape: PASS
UI surface: PASS
provider/materializer/canonical behavior: PASS
worktree clean after validation: PASS
```

## Remaining future work

This close-out does not implement a real upstream login/session provider.

Remaining future work should start as a separate design track:

```text
Connect the real upstream authentication/session provider to the server-derived Source Health assigns
Define dedicated unauthenticated internal UI access policy if bounded shell behavior is not sufficient
Define any production audit convention changes for missing/unauthenticated SourceHealthAuthContext
Close or remove test-only fallback only after production provider wiring is fully proven
```

Recommended next track:

```text
Design upstream auth provider handoff for SourceHealthAuthContext
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
reintroduces request-param actor_permissions as production authority
adds login UI in the same PR as auth context provider wiring
adds poll UI
adds audit UI
adds public Source Health UI
changes backend response shapes without focused contract tests
stores or returns raw actor/session/request identifiers
returns headers, cookies, tokens, provider credentials, raw provider payloads, canonical payloads, stack traces, SQL details, or unbounded diagnostics
changes provider/materializer/canonical behavior
changes public API/feed behavior
adds duplicate controller modules
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
- [x] Records validation and closes the production session source workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_production_session_source_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
