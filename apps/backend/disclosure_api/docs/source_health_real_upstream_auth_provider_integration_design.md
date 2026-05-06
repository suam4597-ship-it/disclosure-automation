# Source Health Real Upstream Auth Provider Integration Design

This document designs how a real upstream authentication/session provider should integrate with the already-locked Source Health upstream handoff pipeline.

This PR is documentation-only. It does not add runtime provider integration, login UI, logout UI, identity provider callback routes, routes, controllers, plugs, templates, migrations, backend response-shape changes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-source-health-upstream-auth-handoff-closeout-v1
base source: PR #298 Lock source health upstream auth handoff
stream: real upstream auth/session provider integration design
status: docs-only design
```

## Why this track is next

The previous upstream handoff workset locked:

```text
upstream bounded assigns -> SourceHealthUpstreamAuthHandoff
SourceHealthUpstreamAuthHandoff -> source_health_* assigns
SourceHealthProductionAuthContext -> SourceHealthAuthContext
SourceHealthAuthContext is authoritative
request params cannot override upstream/production context
missing upstream handoff with fallback disabled preserves bounded denial / not_rendered behavior
```

The next step is to define how a real app-level auth/session provider should supply the already-bounded upstream assigns.

## Goal

Define the integration contract between a real upstream authentication/session provider and Source Health.

The provider integration must output only these bounded upstream assigns:

```text
:upstream_actor_id_hash
:upstream_request_id_hash
:upstream_session_id_hash
:upstream_role_names
:upstream_source_health_permissions
```

These are then consumed by the existing Source Health handoff and production context pipeline.

## Non-goals

This design does not implement:

```text
login UI
logout UI
identity provider callback routes
OAuth/OIDC/SAML flow
session table or migration
cookie parsing inside Source Health gates
token parsing inside Source Health gates
new Source Health routes
new controllers
backend response-shape changes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical behavior changes
public API/feed behavior changes
```

A real provider integration PR must remain separate from any user-facing login UX or identity-provider callback routing.

## Ownership boundary

### Real upstream auth provider owns

```text
reading and validating cookies/tokens/headers
validating session freshness
resolving raw user identity
resolving raw session identity
resolving organization/tenant context if applicable
mapping internal roles to Source Health roles or permissions
hashing actor/session/request identifiers before handoff
populating upstream_* bounded assigns
```

### Source Health handoff owns

```text
copying bounded upstream_* assigns to source_health_* assigns
building SourceHealthAuthContext from source_health_* assigns
checking source_health permissions for UI/recheck/poll
preserving bounded response shapes
preserving audit redaction boundaries
```

### Source Health must not own

```text
validating cookies/tokens directly
parsing Authorization headers directly
trusting query/body actor fields
storing raw user/session/request identifiers
returning raw auth/session details in responses
owning provider callback routes
owning login UI
```

## Required provider output

A future provider integration should set:

```elixir
conn
|> assign(:upstream_actor_id_hash, actor_id_hash)
|> assign(:upstream_request_id_hash, request_id_hash)
|> assign(:upstream_session_id_hash, session_id_hash)
|> assign(:upstream_role_names, source_health_role_names)
|> assign(:upstream_source_health_permissions, source_health_permissions)
```

Field rules:

```text
upstream_actor_id_hash -> hash of real authenticated actor/user identity
upstream_request_id_hash -> hash or bounded correlation identifier for the request
upstream_session_id_hash -> hash of authenticated session identity
upstream_role_names -> Source Health bounded role names
upstream_source_health_permissions -> optional allowlisted Source Health permissions
```

The provider may omit `:upstream_source_health_permissions` when role mapping is sufficient.

## Required role mapping

The provider must map internal roles to one or more of:

```text
source_health_viewer
source_health_operator
source_health_poll_operator
source_health_admin
```

Locked permission meanings:

```text
source_health_viewer -> source_health:read
source_health_operator -> source_health:read, source_health:recheck
source_health_poll_operator -> source_health:read, source_health:poll
source_health_admin -> source_health:read, source_health:recheck, source_health:poll
```

If an internal role does not map to Source Health, it must not be handed to Source Health.

## Hashing and redaction requirements

Provider integration must hash before setting upstream assigns.

Forbidden upstream assign values:

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

Allowed values:

```text
hashed actor id
hashed request id
hashed session id
bounded Source Health role names
bounded Source Health permissions
```

Hashing should be stable enough for operational audit correlation while preventing raw identity exposure.

## Request-param authority remains forbidden

A real provider integration must not treat these as authority:

```text
query actor_permissions
body actor_permissions
query actor_id_hash
body actor_id_hash
query role_names
body role_names
headers directly consumed by Source Health
cookies directly consumed by Source Health
tokens directly consumed by Source Health
```

Only the upstream provider may validate headers/cookies/tokens, and it may hand only bounded, already-validated assigns to Source Health.

## Route integration recommendation

Provider integration should happen before the existing Source Health handoff pipeline.

Current locked Source Health pipeline order:

```text
SourceHealthUpstreamAuthHandoff
SourceHealthProductionAuthContext
Source Health UI/recheck/poll authorization
```

Future provider integration should sit before `SourceHealthUpstreamAuthHandoff`:

```text
RealUpstreamAuthProvider
SourceHealthUpstreamAuthHandoff
SourceHealthProductionAuthContext
Source Health UI/recheck/poll authorization
```

Do not add new Source Health routes for this integration.

## Missing/invalid auth behavior

If the provider cannot validate authentication:

```text
it should not set upstream_* assigns
Source Health handoff passes through unchanged
SourceHealthProductionAuthContext has no production context to build
fallback disabled means request params cannot authorize
API recheck/poll remain bounded 403
UI remains bounded/default until dedicated UI auth policy changes
```

Do not add login redirect behavior in the same PR as provider integration.

## Audit behavior

Audit writers should continue receiving only bounded context from SourceHealthAuthContext.

Allowed audit fields remain:

```text
actor_id_hash
request_id_hash
session_id_hash
actor_permissions
role_names
redaction_status
created_at
```

Forbidden audit fields remain:

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

Any audit storage or response change must be a separate contract PR.

## Recommended rollout sequence

### PR A. Real provider integration contract tests

Recommended title:

```text
Add source health real upstream auth provider integration contract tests
```

Recommended coverage:

```text
provider output is bounded upstream_* assign set
raw provider identity/session/request material is forbidden
internal roles map only to bounded Source Health role names/permissions
request query/body cannot override provider output
missing provider output preserves bounded denial/default behavior
provider integration does not add login UI or callback routes
provider integration does not add poll UI, audit UI, or public Source Health UI
```

### PR B. Provider adapter skeleton

Recommended title:

```text
Add source health upstream auth provider adapter skeleton
```

Recommended scope:

```text
small adapter module that transforms an already-authenticated app auth struct/assign into upstream_* assigns
no cookie/token/header parsing inside Source Health
no login UI
no callback routes
focused tests only
```

### PR C. Pipeline wiring

Recommended title:

```text
Wire source health upstream auth provider adapter into operator pipeline
```

Recommended scope:

```text
wire provider adapter before SourceHealthUpstreamAuthHandoff
no new routes
no login UI
no callback routes
no response-shape changes
focused route-wiring tests only
```

### PR D. Close-out

Recommended title:

```text
Lock source health real upstream auth provider integration
```

Recommended content:

```text
record implementation commits
record focused and adjacent regression results
record any remaining dedicated UI auth policy work
```

## Stop conditions

Stop and re-scope if future work:

```text
adds login UI in the same PR
adds identity provider callback routes in the same PR
parses cookies/tokens directly inside Source Health gates
reintroduces query/body actor_permissions as production authority
changes backend JSON response shapes without focused contract tests
adds poll UI
adds audit UI
adds public Source Health UI
stores or returns raw actor/session/request identifiers
returns headers, cookies, tokens, provider credentials, raw payloads, canonical payloads, stack traces, SQL details, or unbounded diagnostics
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
- [x] Defines the next real provider integration contract-test PR.

## Validation

This design PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_real_upstream_auth_provider_integration_design.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
