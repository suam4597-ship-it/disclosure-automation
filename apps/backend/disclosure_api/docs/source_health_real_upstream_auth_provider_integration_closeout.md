# Source Health Real Upstream Auth Provider Integration Close-out

This document closes out the Source Health real upstream auth provider integration workset.

This PR is documentation-only. It records locked behavior and validation evidence from the real upstream auth/session provider integration design, contract tests, adapter skeleton, and operator route wiring PRs.

## Baseline

```text
base branch: chatgpt-source-health-provider-adapter-route-wire-v1
base source: PR #302 Wire source health upstream auth provider adapter into operator pipeline
stream: source health real upstream auth provider integration
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #299 Design real upstream auth session provider integration for Source Health handoff
PR #300 Add source health real upstream auth provider integration contract tests
PR #301 Add source health upstream auth provider adapter skeleton
PR #302 Wire source health upstream auth provider adapter into operator pipeline
```

## Locked integration behavior

The real upstream auth provider integration path is now locked as follows:

```text
bounded app auth assign present -> SourceHealthUpstreamAuthProviderAdapter copies it to upstream_* assigns
upstream_* assigns present -> SourceHealthUpstreamAuthHandoff copies them to source_health_* assigns
source_health_* assigns present -> SourceHealthProductionAuthContext builds SourceHealthAuthContext
SourceHealthAuthContext present -> SourceHealthAuthContext is authoritative
request params cannot override app/upstream/production context
missing app auth with fallback disabled -> bounded denial / not_rendered behavior
```

## Locked app-auth input

The provider adapter reads only:

```text
:source_health_app_auth
```

Allowed keys inside that bounded app-auth assign:

```text
actor_id_hash
request_id_hash
session_id_hash
role_names
source_health_permissions
```

The provider adapter does not parse or trust:

```text
cookies
headers
tokens
query params
request body fields
raw actor/session/request identifiers
provider credentials
private actor context
```

## Locked route pipeline order

The existing Source Health operator routes now use this pipeline order:

```text
SourceHealthUpstreamAuthProviderAdapter
SourceHealthUpstreamAuthHandoff
SourceHealthProductionAuthContext
Source Health UI/recheck/poll authorization
```

The adapter is wired only on existing Source Health operator routes:

```text
/admin/source-health
/admin/source-health/:source_key
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
/api/admin/sources/:source_key/poll
```

No new routes were added.

## Non-Source Health routes remain outside the pipeline

Duplicate-group routes remain outside the Source Health auth provider adapter pipeline.

This boundary is important because the adapter is scoped to Source Health operator protection only.

## Locked route behavior

Focused route-wiring tests lock these behaviors:

```text
bounded app auth operator enables UI recheck action
bounded app auth viewer keeps UI recheck disabled despite query escalation
bounded app auth operator authorizes backend recheck with fallback disabled
missing app auth denies backend recheck despite body actor_permissions
bounded app auth recheck-only operator does not authorize poll
bounded app auth poll operator reaches the existing idempotency gate
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
logout UI
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

Bounded behavior remains existing surface-specific behavior:

```text
recheck unauthorized -> bounded 403 source health recheck not allowed
poll unauthorized -> bounded 403 source poll not allowed
unknown source -> bounded 404 source not found
poll operator with missing idempotency key -> existing bounded 409 missing_idempotency_key
```

## Validation evidence

PR #302 local validation at head:

```text
7c4a6d0d235633a646f5a16e38f9c415063257ab
```

Focused validation:

```text
17 tests, 0 failures
```

Adjacent Source Health/auth regression:

```text
126 tests, 0 failures
```

PR review:

```text
4235635433
```

Validation summary:

```text
diff scope: PASS, expected 2 files only
provider adapter route wiring: PASS
source health route scope: PASS
duplicate-group route impact: PASS
app auth operator UI: PASS
app auth viewer UI: PASS
backend recheck: PASS
missing app auth: PASS
poll authorization/idempotency gate boundary: PASS
route/response shape: PASS
UI/callback surface: PASS
worktree clean after validation: PASS
```

## Remaining future work

This close-out does not add user-facing login UI or identity provider callback routes.

Remaining future work should start as separate, focused design tracks:

```text
Design dedicated unauthenticated internal UI access policy if bounded shell behavior is not sufficient
Design user-facing login/session UX if needed
Design identity provider callback routes if needed
Define production audit convention changes, if any, after real provider usage
Eventually close or remove test-only fallback after provider-backed operation is fully proven
```

Recommended next track:

```text
Design dedicated source health unauthenticated UI access policy
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
reintroduces request-param actor_permissions as production authority
adds login UI in the same PR as Source Health auth adapter changes
adds identity provider callback routes in the same PR as Source Health auth adapter changes
adds poll UI
adds audit UI
adds public Source Health UI
changes backend response shapes without focused contract tests
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
- [x] Does not change backend response shapes.
- [x] Keeps Source Health auth/session work limited to operator protection.
- [x] Records validation and closes the real upstream auth provider integration workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_real_upstream_auth_provider_integration_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
