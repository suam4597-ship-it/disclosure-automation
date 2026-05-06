# Source Health Upstream Auth Provider Handoff Design

This document designs the handoff between the future upstream authentication/session provider and `SourceHealthAuthContext`.

This PR is documentation-only. It does not add login UI, authentication provider integration, runtime session lookup, routes, controllers, plugs, templates, migrations, backend response-shape changes, UI controls, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-source-health-production-session-closeout-v1
base source: PR #293 Lock source health production session source
stream: source health upstream auth provider handoff design
status: docs-only design
```

## Why this track is next

The previous Source Health production session workset locked that:

```text
server-derived Source Health assigns can build SourceHealthAuthContext
SourceHealthAuthContext is authoritative when present
request params cannot override production context
production context wins over test helper context
Source Health operator routes are wired to consume production SourceHealthAuthContext when assigns exist
```

The next step is to define how an upstream auth provider should supply those server-derived assigns without broadening the Source Health surface.

## Goal

Define the minimal contract by which an upstream authentication/session layer can hand bounded auth information to Source Health.

The handoff must produce only these bounded assigns:

```text
:source_health_actor_id_hash
:source_health_request_id_hash
:source_health_session_id_hash
:source_health_role_names
:source_health_permissions
```

These assigns are consumed by:

```text
DisclosureAutomationWeb.SourceHealthProductionAuthContext
DisclosureAutomationWeb.SourceHealthAuthContext
```

## Non-goals

This design does not implement:

```text
login UI
logout UI
session store
identity provider integration
OAuth/OIDC/SAML callback handling
cookie parsing inside Source Health gates
header/token parsing inside Source Health gates
new routes
new controllers
new migrations
backend response-shape changes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical behavior changes
public API/feed behavior changes
```

## Ownership boundary

### Upstream auth provider owns

```text
validating user session
validating cookies/tokens/headers
resolving raw user identity
resolving raw session identity
resolving user roles
creating or retrieving request correlation identity
hashing raw actor/session/request identifiers before Source Health handoff
populating bounded Source Health assigns
```

### Source Health owns

```text
consuming bounded Source Health assigns
building SourceHealthAuthContext
checking source_health permissions
rendering bounded UI state
performing bounded recheck/poll authorization
recording bounded audit context
refusing request-param actor_permissions authority
```

### Source Health must not own

```text
parsing cookies for identity
parsing tokens for identity
trusting raw headers as identity
trusting query/body actor fields as identity
storing raw user/session/request identifiers
returning raw auth/session data in responses
```

## Required upstream handoff assigns

The upstream provider should assign these values before Source Health operator routes are called:

```elixir
conn
|> assign(:source_health_actor_id_hash, actor_id_hash)
|> assign(:source_health_request_id_hash, request_id_hash)
|> assign(:source_health_session_id_hash, session_id_hash)
|> assign(:source_health_role_names, role_names)
|> assign(:source_health_permissions, permissions)
```

Field requirements:

```text
source_health_actor_id_hash -> server-derived hash of the authenticated actor/user
source_health_request_id_hash -> server-derived request correlation hash
source_health_session_id_hash -> server-derived session hash
source_health_role_names -> server-derived role names, bounded to Source Health relevant roles
source_health_permissions -> optional server-derived explicit Source Health permissions, allowlisted by SourceHealthAuthContext
```

The upstream provider may omit `:source_health_permissions` if roles are sufficient. `SourceHealthAuthContext` will derive permissions from roles and then allowlist any explicit permissions if provided.

## Required role names

Recommended role names remain:

```text
source_health_viewer
source_health_operator
source_health_poll_operator
source_health_admin
```

Role meanings:

```text
source_health_viewer -> source_health:read
source_health_operator -> source_health:read, source_health:recheck
source_health_poll_operator -> source_health:read, source_health:poll
source_health_admin -> source_health:read, source_health:recheck, source_health:poll
```

Upstream provider may use different internal role names, but it must map them to the bounded Source Health role names or bounded Source Health permissions before handoff.

## Handoff location recommendation

The upstream handoff should occur before these existing Source Health route pipelines:

```text
/admin/source-health
/admin/source-health/:source_key
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
/api/admin/sources/:source_key/poll
```

Do not add new Source Health routes for this handoff.

Recommended implementation pattern for future PR:

```text
1. upstream app auth plug validates session
2. upstream plug assigns bounded Source Health handoff fields
3. existing SourceHealthProductionAuthContext plug builds SourceHealthAuthContext when assigns are present
4. existing UI/recheck/poll gates consume SourceHealthAuthContext
```

## Missing or unauthenticated handoff behavior

If upstream auth provider cannot validate a session, it should not set Source Health handoff assigns.

Current Source Health behavior then remains:

```text
fallback disabled -> no request-param authority
API recheck unauthorized -> bounded 403
API poll unauthorized -> bounded 403
UI action state without context -> bounded not_rendered/default state until dedicated UI auth policy is implemented
```

Any future change to UI unauthenticated behavior, such as redirect or bounded 401/403, must be a separate focused design/contract PR.

## Redaction and hashing requirements

The upstream auth provider must hash before Source Health handoff.

Forbidden handoff values:

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
private_actor_context
```

Allowed handoff values:

```text
actor_id_hash
request_id_hash
session_id_hash
role_names
source_health permissions
```

The hashing scheme should be stable enough for audit correlation in the intended operational window while preventing raw identity exposure.

## Request-param policy remains locked

The upstream handoff must not reintroduce request-param authority.

Still forbidden as production authority:

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

If these appear in query params or request body, Source Health must ignore them for production authorization when fallback is disabled.

## Audit handoff policy

Source Health audit writers may use only the bounded values derived from the handoff:

```text
actor_id_hash
request_id_hash
session_id_hash
actor_permissions
role_names
redaction_status
created_at
```

Audit writers must not receive or persist:

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
private_actor_context
```

## Recommended rollout sequence

### PR A. Upstream handoff contract tests

Recommended title:

```text
Add source health upstream auth handoff contract tests
```

Recommended coverage:

```text
handoff fields are exactly the bounded Source Health assign set
raw identity/session/request fields are forbidden
role mapping can be projected to Source Health roles/permissions
request body cannot override handoff assigns
missing handoff preserves bounded denial/default behavior
handoff does not add login UI, poll UI, audit UI, or public Source Health UI
```

### PR B. Upstream handoff plug skeleton

Recommended title:

```text
Add source health upstream auth handoff plug skeleton
```

Recommended scope:

```text
small plug that copies already-authenticated bounded values from existing upstream auth assigns to Source Health assigns
no identity provider integration
no login UI
no new routes
focused tests only
```

### PR C. Handoff wiring

Recommended title:

```text
Wire upstream auth handoff into source health operator pipeline
```

Recommended scope:

```text
add the upstream handoff plug before SourceHealthProductionAuthContext
SourceHealthProductionAuthContext continues to build context from bounded assigns
no poll UI
audit UI remains absent
public Source Health UI remains absent
```

### PR D. Close-out

Recommended title:

```text
Lock source health upstream auth handoff
```

Recommended content:

```text
record implementation commits
record focused and adjacent regression results
record remaining dedicated UI auth policy work
```

## Stop conditions

Stop and re-scope if future implementation pressure appears to require:

```text
adding login UI in the same PR
adding identity provider callback routes in the same PR
adding poll UI
adding audit UI
adding public Source Health UI
changing backend JSON response shapes
storing or returning raw user/session/request identifiers
trusting query/body actor fields as production authority
parsing cookies/tokens directly inside Source Health gates
changing provider/materializer/canonical behavior
changing public API/feed behavior
adding duplicate controller modules
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
- [x] Defines the next upstream handoff contract-test PR.

## Validation

This design PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_upstream_auth_provider_handoff_design.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
