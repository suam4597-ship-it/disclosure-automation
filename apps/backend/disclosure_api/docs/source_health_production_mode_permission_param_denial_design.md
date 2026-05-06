# Source Health Production-mode Permission Param Denial Design

This document designs how Source Health should make request-param `actor_permissions` non-authoritative outside the explicit test harness.

This PR is documentation-only. It does not remove fallback behavior, change runtime authorization behavior, change routes, change response shapes, add UI surfaces, add migrations, or change provider/materializer/canonical behavior.

## Baseline

```text
base branch: chatgpt-source-health-legacy-permission-inventory-v1
base source: PR #284 Add source health legacy permission param inventory
stream: source health production auth/session replacement
status: docs-only design
```

## Why this design is next

The production auth/session replacement design chose this phased strategy:

```text
Phase 1: introduce auth context helper with explicit test harness mode
Phase 2: update source health auth plugs to read server-derived context first
Phase 3: update tests to use helper/session setup instead of raw params
Phase 4: make request-param actor_permissions non-authoritative outside test harness
Phase 5: remove or quarantine direct request-param permission authority
```

Phases 1-3 are mostly complete for the active Source Health operator surfaces.

PR #284 inventoried the remaining compatibility surfaces:

```text
internal Source Health UI recheck action fallback
Source Health recheck authorization fallback
Source Health poll authorization fallback
```

This design defines Phase 4 before runtime changes are made.

## Goal

Production-mode behavior must not grant Source Health permissions from request params.

Request params include both query string and request body values such as:

```text
actor_permissions=source_health:read
actor_permissions=source_health:recheck
actor_permissions=source_health:poll
actor_permissions[]=source_health:read
actor_permissions[]=source_health:recheck
actor_permissions[]=source_health:poll
```

The only production authority should be a server-derived bounded SourceHealthAuthContext built from authenticated session, server-side user identity, role mapping, and permission mapping.

## Non-goals

This design does not implement:

```text
production auth/session lookup
new login routes
new controllers
new migrations
new UI controls
poll UI
audit UI
public Source Health UI
backend response shape changes
provider/materializer/canonical behavior changes
public API/feed changes
monitoring/dashboard/alert changes
```

This design also does not remove all compatibility fallback immediately. It defines the safe target and recommended rollout.

## Desired authority model

### Production mode

```text
SourceHealthAuthContext present and contains required permission -> allow bounded action
SourceHealthAuthContext present and lacks required permission -> deny bounded action
SourceHealthAuthContext absent -> deny bounded action according to route convention
request-param actor_permissions present -> ignore for authority
request-param actor_permissions malformed -> ignore for authority
```

### Explicit test-harness mode

```text
SourceHealthAuthContext injected by test helper -> allow/deny according to helper context
legacy request-param fallback may remain temporarily for old characterization tests only
fallback must be explicitly unavailable in production config
```

### Development/manual smoke mode

The preferred manual smoke path should use helper/session injection or a dedicated local-only auth context source rather than request-param authority.

If a temporary manual fallback is kept, it must be clearly gated away from production.

## Config gate recommendation

Introduce an explicit config gate before removing all fallback:

```text
config :disclosure_automation, :source_health_permission_param_fallback, :test_only
```

Recommended values:

```text
:disabled -> request-param actor_permissions never grant authority
:test_only -> request-param actor_permissions may be used only when Mix.env() == :test
:legacy_compat -> temporary compatibility mode for local migration only; forbidden in production
```

Production config must resolve to:

```text
:disabled
```

Test config may temporarily resolve to:

```text
:test_only
```

The fallback helper should fail closed for unknown config values.

## Recommended helper shape

Add a small helper instead of leaving duplicated fallback checks in multiple modules.

Recommended module location:

```text
DisclosureAutomationWeb.SourceHealthAuthContext
```

Recommended functions:

```text
request_param_fallback_enabled?/0
legacy_request_param_permissions(conn_or_params)
permissions_for_authorization(conn, params)
permission_state_requested?(conn, params)
```

Recommended behavior:

```text
permissions_for_authorization/2:
  if SourceHealthAuthContext is available:
    return context permissions
  else if request_param_fallback_enabled?():
    return allowlisted request-param permissions
  else:
    return []
```

For UI recheck action state:

```text
permission_state_requested?/2:
  true when SourceHealthAuthContext is available
  true when request-param fallback is enabled and actor_permissions param is present
  false otherwise
```

This preserves the current default UI behavior where no permission state is requested while preventing production query-string authority.

## Surface-specific target behavior

### 1. Internal Source Health UI recheck action

Current compatibility surface:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_ui_controller.ex
```

Current behavior:

```text
SourceHealthAuthContext wins when present.
If no context is present, actor_permissions query can request enabled/disabled UI action state.
```

Production target:

```text
SourceHealthAuthContext with source_health:read -> disabled/read_only or visible per product policy
SourceHealthAuthContext with source_health:recheck -> enabled bounded recheck contract
SourceHealthAuthContext absent -> default not_rendered or bounded unauthenticated/forbidden behavior per future UI auth policy
actor_permissions query present without auth context -> not authority in production
```

Do not add:

```text
poll UI
audit UI
public Source Health UI
provider/materializer/canonical controls
```

### 2. Source Health recheck authorization

Current compatibility surface:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_recheck_authorization.ex
```

Current behavior:

```text
SourceHealthAuthContext wins when present.
If no context is present, body/query actor_permissions can authorize source_health:recheck.
```

Production target:

```text
SourceHealthAuthContext with source_health:recheck -> allow
SourceHealthAuthContext without source_health:recheck -> bounded 403
SourceHealthAuthContext absent -> bounded 403 or unauthenticated convention in future production auth integration
actor_permissions param present without context -> ignore/deny in production
```

Audit target:

```text
audit auth_params use SourceHealthAuthContext when present
when no SourceHealthAuthContext is present in production, audit should use bounded unknown/anonymous/session-missing context or deny before audit according to explicit future contract
request params must not supply raw/private audit identity material
```

### 3. Source Health poll authorization

Current compatibility surface:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/source_health_poll_authorization.ex
```

Current behavior:

```text
SourceHealthAuthContext wins when present.
If no context is present, body/query actor_permissions can authorize source_health:poll.
```

Production target:

```text
SourceHealthAuthContext with source_health:poll -> allow to next poll gates
SourceHealthAuthContext without source_health:poll -> bounded 403
SourceHealthAuthContext absent -> bounded 403 or unauthenticated convention in future production auth integration
actor_permissions param present without context -> ignore/deny in production
```

Poll-specific gates remain unchanged:

```text
unknown source -> bounded 404
missing idempotency key -> bounded 409
rate limited -> bounded 429
reused -> bounded 202
accepted path remains gated
```

Do not add poll UI as part of this work.

## Recommended rollout sequence

### PR A. Contract tests for production-mode param denial

Recommended title:

```text
Add source health production-mode permission param denial contract tests
```

Recommended tests:

```text
production-mode UI query actor_permissions does not enable recheck action without SourceHealthAuthContext
production-mode recheck body actor_permissions does not authorize without SourceHealthAuthContext
production-mode poll body actor_permissions does not authorize without SourceHealthAuthContext
explicit SourceHealthAuthContext still authorizes recheck/poll
explicit read-only SourceHealthAuthContext still denies recheck/poll despite body escalation
fallback remains available only in test-only compatibility mode if explicitly configured
```

### PR B. Shared fallback gate helper

Recommended title:

```text
Gate source health legacy permission params behind test harness config
```

Recommended changes:

```text
add SourceHealthAuthContext request-param fallback helper
update UI/recheck/poll authorization to call helper
set production behavior to deny/ignore request-param authority
keep focused compatibility tests for explicit test-only fallback if still needed
```

### PR C. Legacy fallback close-out

Recommended title:

```text
Lock source health production-mode permission param denial
```

Recommended content:

```text
record contract tests
record focused/adjacent regression results
record remaining future production session integration work
```

## Request-param handling policy

Production behavior should not treat these as authority:

```text
actor_permissions
actor_id_hash
request_id_hash
session_id_hash
role_names
redaction_status
created_at
route_operation
result_status
idempotency_status
rate_limit_status
```

Request body may still carry non-authoritative bounded operational fields already accepted by existing contracts, such as:

```text
idempotency_key_hash
reason_redacted
```

But actor/session/request identity and permissions must come from the server-derived context once production auth is connected.

## Response-shape policy

Production-mode permission param denial should preserve existing response shapes unless a focused contract PR explicitly changes them.

Recommended initial behavior:

```text
recheck unauthorized due to missing/insufficient auth context -> existing bounded 403 shape
poll unauthorized due to missing/insufficient auth context -> existing bounded 403 shape
unknown source remains existing bounded 404 shape
UI with no valid auth context remains default not_rendered or existing bounded UI behavior until future UI auth policy is implemented
```

Do not add raw auth diagnostics to HTTP responses.

## Redaction policy

The denial implementation must not expose:

```text
raw_actor_id
raw_user_id
raw_session_id
raw_request_id
email
headers
cookies
tokens
provider_credentials
raw_provider_payload
canonical_payload
private_actor_context
stack_trace
sql_details
unbounded_diagnostics
audit_event_id
```

## Stop conditions

Stop and re-scope if implementation pressure appears to require:

```text
adding poll UI
adding audit UI
adding public Source Health UI
changing backend JSON response shapes
adding production login/session integration in the same PR
removing all fallback without first landing contract tests
allowing request-param actor_permissions in production
returning raw auth/session details in responses
changing provider/materializer/canonical behavior
changing public API/feed behavior
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
- [x] Updates workflow state by defining the next production-mode param-denial contract-test PR.

## Validation

This design PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_production_mode_permission_param_denial_design.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
