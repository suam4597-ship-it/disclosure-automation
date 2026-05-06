# Source Health Upstream Auth Handoff Close-out

This document closes out the Source Health upstream auth handoff workset.

This PR is documentation-only. It records the locked behavior and validation evidence from the upstream auth provider handoff design, contract tests, plug skeleton, and route wiring PRs.

## Baseline

```text
base branch: chatgpt-source-health-upstream-handoff-route-wire-v1
base source: PR #297 Wire upstream auth handoff into source health operator pipeline
stream: source health upstream auth handoff
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #294 Design upstream auth provider handoff for SourceHealthAuthContext
PR #295 Add source health upstream auth handoff contract tests
PR #296 Add source health upstream auth handoff plug skeleton
PR #297 Wire upstream auth handoff into source health operator pipeline
```

## Locked upstream handoff behavior

The upstream auth handoff behavior is now locked as follows:

```text
upstream bounded assigns present -> SourceHealthUpstreamAuthHandoff copies them to Source Health assigns
SourceHealthProductionAuthContext then builds SourceHealthAuthContext from Source Health assigns
SourceHealthAuthContext is authoritative when present
request params cannot override upstream/production context
missing upstream handoff with fallback disabled -> bounded denial / not_rendered behavior
```

## Locked handoff assigns

The only upstream handoff assigns copied into Source Health are:

```text
:upstream_actor_id_hash -> :source_health_actor_id_hash
:upstream_request_id_hash -> :source_health_request_id_hash
:upstream_session_id_hash -> :source_health_session_id_hash
:upstream_role_names -> :source_health_role_names
:upstream_source_health_permissions -> :source_health_permissions
```

The handoff plug does not parse:

```text
cookies
headers
tokens
query params
request body fields
raw actor/session/request identifiers
```

## Runtime surfaces wired

The upstream handoff plug is:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_upstream_auth_handoff.ex
```

The plug is wired before `SourceHealthProductionAuthContext` on existing Source Health operator routes only:

```text
/admin/source-health
/admin/source-health/:source_key
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
/api/admin/sources/:source_key/poll
```

No new routes were added.

## Non-Source Health routes remain outside the handoff pipeline

Duplicate-group routes remain outside the upstream handoff and production Source Health auth context pipeline.

This boundary remains important because this auth workset is scoped to Source Health operator protection only.

## Locked route behavior

Focused route-wiring tests lock these behaviors:

```text
upstream operator handoff enables bounded UI recheck action
upstream viewer handoff keeps UI recheck disabled despite query escalation
upstream operator handoff authorizes backend recheck with fallback disabled
missing upstream handoff denies backend recheck despite body actor_permissions
upstream recheck-only handoff does not authorize poll
upstream poll handoff passes poll authorization and reaches the existing idempotency gate
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

PR #297 local validation at head:

```text
ae69003db9bc8afe3121c10051d1b441b4f7adc4
```

Focused validation:

```text
17 tests, 0 failures
```

Adjacent Source Health/auth regression:

```text
104 tests, 0 failures
```

PR review:

```text
4235328101
```

Validation summary:

```text
diff scope: PASS, expected 2 files only
upstream handoff route wiring: PASS
source health route scope: PASS
duplicate-group route impact: PASS
upstream operator UI: PASS
upstream viewer UI: PASS
backend recheck: PASS
missing upstream handoff: PASS
poll authorization/idempotency gate boundary: PASS
route/response shape: PASS
UI/callback surface: PASS
provider/materializer/canonical behavior: PASS
worktree clean after validation: PASS
```

## Remaining future work

This close-out does not implement a real upstream login/session provider. It only locks the bounded handoff contract and route wiring.

Remaining future work should start as a separate design track:

```text
Connect real upstream authentication/session provider to upstream_* bounded assigns
Define dedicated unauthenticated internal UI access policy if bounded shell behavior is not sufficient
Define production audit convention changes, if any, after real provider wiring
Eventually close or remove test-only fallback after production provider wiring is fully proven
```

Recommended next track:

```text
Design real upstream auth/session provider integration for Source Health handoff
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
reintroduces request-param actor_permissions as production authority
adds login UI in the same PR as provider handoff wiring
adds identity provider callback routes in the same PR as Source Health handoff wiring
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
- [x] Records validation and closes the upstream auth handoff workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_upstream_auth_handoff_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
