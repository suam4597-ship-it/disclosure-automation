# Source Health Internal UI Access Policy Close-out

This document closes out the Source Health internal UI access policy workset.

This PR is documentation-only. It records locked behavior and validation evidence from the internal UI access policy design, contract tests, access guard implementation, and follow-up regression fix.

## Baseline

```text
base branch: chatgpt-source-health-ui-access-guard-v1
base source: PR #306 Add source health internal UI access guard
stream: source health internal UI access policy
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #304 Design source health internal UI access policy
PR #305 Add source health internal UI access policy contract tests
PR #306 Add source health internal UI access guard
```

## Locked UI access behavior

The Source Health internal UI routes now use an explicit bounded access guard.

Routes covered:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Locked behavior:

```text
missing SourceHealthAuthContext -> 403 text/plain bounded denial
SourceHealthAuthContext without source_health:read -> 403 text/plain bounded denial
SourceHealthAuthContext with source_health:read -> bounded list/detail shell allowed
SourceHealthAuthContext with source_health:read + source_health:recheck -> bounded detail shell with recheck action enabled
query actor_permissions cannot bypass missing context/read requirement
```

## Locked denial bodies

Missing auth context:

```text
Source health access denied
state=forbidden
reason=missing_source_health_auth_context
```

Missing read permission:

```text
Source health access denied
state=forbidden
reason=missing_source_health_read_permission
```

## Runtime surfaces changed

Access guard module:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_internal_ui_access_guard.ex
```

Router wiring:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
```

The guard is wired only to the Source Health internal UI scope.

## Runtime surfaces not changed

This workset does not add or change:

```text
JSON API response shapes
new routes
new controllers beyond the guard plug
new templates
new migrations
frontend static shell
login UI
redirect behavior
identity provider callback routes
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

JSON API routes remain outside this UI guard behavior.

Duplicate-group routes remain unaffected.

## Tests updated

Existing UI tests that need to view Source Health list/detail now pass explicit read context:

```text
apps/backend/disclosure_api/test/source_health_internal_ui_list_shell_test.exs
apps/backend/disclosure_api/test/source_health_internal_ui_detail_shell_test.exs
apps/backend/disclosure_api/test/source_health_internal_ui_recheck_action_test.exs
apps/backend/disclosure_api/test/source_health_internal_ui_recheck_submit_flow_test.exs
apps/backend/disclosure_api/test/source_health_operator_smoke_test.exs
```

Focused guard tests added:

```text
apps/backend/disclosure_api/test/source_health_internal_ui_access_guard_test.exs
```

Fallback-gate expectations were updated after validation found legacy UI expectations:

```text
apps/backend/disclosure_api/test/source_health_permission_param_fallback_gate_test.exs
```

## Validation evidence

Initial PR #306 validation at head:

```text
aedf7fc6ef67dc9c180c38c2ca2e72e0bbdf93e1
```

Initial focused validation:

```text
36 tests, 0 failures
```

Initial adjacent Source Health/UI/auth regression:

```text
102 tests, 3 failures
```

Initial regression failure cause:

```text
source_health_permission_param_fallback_gate_test.exs still expected legacy UI route behavior of 200 responses without explicit SourceHealthAuthContext.
The new UI access guard correctly returns bounded 403 when SourceHealthAuthContext is missing.
```

Follow-up head:

```text
bb0e289e66f3cfeca2141531dcba7ca33d214b67
```

Focused validation after fix:

```text
42 tests, 0 failures
```

Adjacent Source Health/UI/auth regression after fix:

```text
102 tests, 0 failures
```

PR review:

```text
4236059017
```

Validation summary after fix:

```text
diff scope: PASS, expected 9 files
fallback gate update: PASS
UI access guard: PASS
missing context: PASS
missing read: PASS
query bypass: PASS
read context: PASS
read+recheck context: PASS
route scope: PASS
JSON response shape: PASS
UI/callback surface: PASS
worktree clean after validation: PASS
```

## Remaining future work

This close-out does not add login UI, redirects, or identity provider callback routes.

Remaining future work should start as separate focused design tracks:

```text
Design user-facing login/session UX if required
Design identity provider callback routes if required
Design audit UI separately if ever needed
Design poll UI separately if ever needed
Eventually close or remove test-only fallback after provider-backed operation is fully proven
```

Recommended next track:

```text
Fast MVP frontend/backend deployment smoke and close-out
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
reintroduces request-param actor_permissions as production authority
adds login UI in the same PR as Source Health UI guard changes
adds redirects in the same PR as Source Health UI guard changes
adds identity provider callback routes in the same PR as Source Health UI guard changes
adds poll UI
adds audit UI
adds public Source Health UI
changes backend JSON response shapes without focused contract tests
stores or returns raw actor/session/request identifiers
parses cookies/tokens directly inside Source Health gates
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
- [x] Does not change backend JSON response shapes.
- [x] Keeps Source Health auth/session work limited to operator protection.
- [x] Records validation and closes the internal UI access policy workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_access_policy_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
