# Source Health Production-mode Permission Param Denial Close-out

This document closes out the Source Health production-mode permission-param denial track.

This PR is documentation-only. It records the locked behavior and validation evidence from the production-mode request-param denial design, contract tests, and runtime fallback gate implementation.

## Baseline

```text
base branch: chatgpt-source-health-param-fallback-config-v1
base source: PR #287 Gate source health legacy permission params behind test harness config
stream: source health production-mode permission-param denial
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #284 Add source health legacy permission param inventory
PR #285 Design source health production-mode permission param denial
PR #286 Add source health production-mode permission param denial contract tests
PR #287 Gate source health legacy permission params behind test harness config
```

## Locked production-mode behavior

Production-mode request-param permission authority is now locked as follows:

```text
SourceHealthAuthContext available -> use SourceHealthAuthContext as authority
SourceHealthAuthContext absent and fallback disabled -> no request-param authority
SourceHealthAuthContext absent and fallback test_only -> compatibility fallback only in explicit test config
unknown fallback mode -> fail closed to disabled
```

The default fallback mode is production-safe:

```text
:disabled
```

The test config explicitly enables compatibility fallback:

```text
config :disclosure_automation, :source_health_permission_param_fallback, :test_only
```

## Runtime surfaces routed through the fallback gate

The remaining legacy request-param compatibility surfaces now route through `SourceHealthAuthContext` helper functions:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_ui_controller.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_recheck_authorization.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_poll_authorization.ex
```

Central helper:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_auth_context.ex
```

Helper functions added/used:

```text
request_param_fallback_mode/0
request_param_fallback_enabled?/0
permission_state_requested?/2
permissions_for_authorization/2
legacy_request_param_permissions/1
auth_param_map_for_request/1
```

## Locked fallback-denial behavior

Focused tests now lock that when fallback is disabled:

```text
query actor_permissions does not enable UI recheck action
body actor_permissions does not authorize source health recheck
body actor_permissions does not authorize source health poll
explicit SourceHealthAuthContext still authorizes source health recheck
unknown fallback mode fails closed to :disabled
```

## Locked response and UI boundaries

This track does not add or change:

```text
backend JSON response shapes
routes
migrations
frontend static shell
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

Bounded denial behavior remains the existing surface-specific behavior:

```text
recheck unauthorized -> bounded 403 source health recheck not allowed
poll unauthorized -> bounded 403 source poll not allowed
unknown source -> bounded 404 source not found
UI without valid action-state authority -> not_rendered / disabled bounded state according to route context
```

## Validation evidence

PR #287 local validation at head:

```text
498f58882ce531b293a397a73d2b5882d86b2d8c
```

Focused validation:

```text
34 tests, 0 failures
```

Adjacent Source Health/auth/UI regression:

```text
69 tests, 0 failures
```

PR review:

```text
4234797470
```

Validation summary:

```text
diff scope: PASS, changed files were exactly the expected 6 files
fallback helper behavior: PASS
fallback disabled UI: PASS
fallback disabled recheck: PASS
fallback disabled poll: PASS
explicit auth context with disabled fallback: PASS
unknown fallback mode fail closed: PASS
worktree clean after validation: PASS
```

## Remaining future work

This close-out does not implement real production login/session integration.

Remaining future work should start as a separate design track:

```text
Connect production session/user/role source into SourceHealthAuthContext
Define unauthenticated internal UI convention: redirect, bounded 401, or bounded 403
Define production audit context for missing/unauthenticated SourceHealthAuthContext
Remove or further quarantine legacy fallback after production auth is connected
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
reintroduces request-param actor_permissions as production authority
adds poll UI as part of auth/session work
adds audit UI as part of auth/session work
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
- [x] Records validation and closes the production-mode permission-param denial workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_production_mode_permission_param_denial_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
