# Source Health Production Session Source Design

This document designs the next Source Health production auth/session step: connecting a server-derived production session/user/role source into `SourceHealthAuthContext`.

This PR is documentation-only. It does not add runtime auth/session lookup, routes, controllers, plugs, templates, migrations, backend response-shape changes, UI controls, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-source-health-param-denial-closeout-v1
base source: PR #288 Lock source health production-mode permission param denial
stream: source health production session source design
status: docs-only design
```

## Why this track is next

The previous workset locked production-mode permission-param denial:

```text
SourceHealthAuthContext available -> authoritative
request-param fallback default -> :disabled
request-param fallback in test config -> :test_only
unknown fallback mode -> fail closed to :disabled
query/body actor_permissions cannot authorize UI/recheck/poll when fallback is disabled
explicit SourceHealthAuthContext still authorizes when fallback is disabled
```

The next production hardening step is to define where the production `SourceHealthAuthContext` comes from.

## Goal

Define a production-safe, bounded source for `SourceHealthAuthContext` based on:

```text
authenticated session
server-side user identity
server-side role mapping
server-side permission mapping
server-derived request/session/actor hashes
```

The implementation must preserve the existing Source Health operator boundaries while replacing request-param test harness authority with server-derived production context.

## Non-goals

This design does not implement:

```text
login/session runtime lookup
new authentication provider integration
new routes
new controllers
new plugs
new migrations
new UI controls
poll UI
audit UI
public Source Health UI
backend response-shape changes
provider/materializer/canonical behavior changes
public API/feed behavior changes
monitoring/dashboard/alert changes
```

## Existing SourceHealthAuthContext contract

Current bounded context fields:

```text
actor_id_hash
actor_permissions
request_id_hash
session_id_hash
role_names
redaction_status
created_at
```

Required production behavior:

```text
all raw identity/session/request values are server-derived
all returned values are bounded or hashed
request body and query string cannot override any auth context field
permissions are allowlisted to source_health:read, source_health:recheck, source_health:poll
```

Do not include in the context:

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

## Production session source boundary

Recommended source contract:

```text
conn.assigns.current_user or equivalent authenticated user/session assign
conn.assigns.current_session or equivalent authenticated session assign
conn.assigns.request_id or server-generated request correlation value
server-side role mapping
server-side permission mapping
```

The implementation should not read actor identity or permissions from:

```text
query params
request body
headers supplied directly to Source Health gates
cookies supplied directly to Source Health gates
tokens supplied directly to Source Health gates
```

Headers/cookies/tokens may be used only by a dedicated upstream authentication layer. Source Health should consume only the bounded server-derived result of that layer.

## Recommended module/API shape

Prefer extending the existing helper module:

```text
DisclosureAutomationWeb.SourceHealthAuthContext
```

Recommended functions:

```text
put_source_health_auth_context(conn, context)
fetch_source_health_auth_context(conn)
source_health_auth_context_available?(conn)
build_production_source_health_auth_context(conn)
put_production_source_health_auth_context(conn)
production_source_health_auth_context_available?(conn)
```

Recommended implementation direction:

```text
1. keep existing test helper functions
2. add production context builder that reads bounded server-derived assigns
3. normalize roles -> source_health permissions
4. hash raw actor/session/request identifiers before storing in private/assigns
5. store only bounded context in conn.private or conn.assigns
6. let existing UI/recheck/poll gates keep consuming SourceHealthAuthContext
```

## Role-to-permission mapping

Initial production role mapping should preserve the earlier contract:

```text
source_health_viewer -> source_health:read
source_health_operator -> source_health:read, source_health:recheck
source_health_poll_operator -> source_health:read, source_health:poll
source_health_admin -> source_health:read, source_health:recheck, source_health:poll
```

Non-equivalence rules remain locked:

```text
source_health:read is not enough for recheck
source_health:read is not enough for poll
source_health:recheck is not enough for poll
source_health:poll does not automatically imply source_health:recheck unless explicitly granted by role mapping
```

## Unauthenticated behavior convention

Before runtime implementation, define unauthenticated behavior explicitly.

Recommended initial convention for API routes:

```text
POST /api/admin/source-health/:source_key/recheck without auth context -> bounded 403
POST /api/admin/sources/:source_key/poll without auth context -> bounded 403
```

Reason:

```text
current Source Health auth gates already use bounded 403 for missing/insufficient permission
preserves backend response shape
avoids introducing login redirects into JSON APIs
```

Recommended initial convention for internal UI routes:

```text
GET /admin/source-health without auth context -> keep current bounded list shell until dedicated UI auth gate is designed, or move to bounded 403 in a separate contract PR
GET /admin/source-health/:source_key without auth context -> keep current default not_rendered action state until dedicated UI auth gate is designed
```

Do not add a login page or redirect behavior in the same PR as the production context source. UI access policy should be a separate focused design/contract if needed.

## Audit interaction

Source Health audit writers should prefer bounded server-derived auth context values.

Allowed audit auth fields:

```text
actor_id_hash
request_id_hash
session_id_hash
actor_permissions
role_names
redaction_status
created_at
```

Forbidden audit auth fields:

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

For missing production auth context, audit behavior should remain bounded:

```text
actor_permissions=[]
redaction_status=missing_source_health_auth_context
```

Any future change to audit response shape or audit storage schema must be a separate contract PR.

## Request-param policy remains locked

The production session source must not reintroduce request-param authority.

Still forbidden as authority:

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

These may be present in request bodies for legacy tests or bounded operational context, but they must not grant production authorization.

## Implementation rollout recommendation

### PR A. Production session source contract tests

Recommended title:

```text
Add source health production session source contract tests
```

Recommended tests:

```text
production context fields are bounded and allowlisted
role mapping produces expected source_health permissions
read role cannot recheck or poll
operator role can recheck but cannot poll
poll operator role can poll but cannot recheck
admin role can read/recheck/poll
request body actor_permissions cannot override production context
raw identity/session/request material is absent from context and responses
```

### PR B. Production context helper skeleton

Recommended title:

```text
Add source health production auth context builder
```

Recommended scope:

```text
helper-only implementation
no new routes
no UI access behavior changes
no login/session provider integration beyond reading existing assigns if present
focused tests only
```

### PR C. Wire production context into Source Health operator pipelines

Recommended title:

```text
Wire production source health auth context into operator routes
```

Recommended scope:

```text
small plug or pipeline helper
existing UI/recheck/poll gates consume SourceHealthAuthContext unchanged
no poll UI
audit UI remains absent
public Source Health UI remains absent
```

### PR D. Close-out

Recommended title:

```text
Lock source health production session source
```

Recommended content:

```text
record implementation commits
record focused and adjacent regression results
record remaining UI login/access policy work
```

## Stop conditions

Stop and re-scope if implementation pressure appears to require:

```text
adding login UI
adding poll UI
adding audit UI
adding public Source Health UI
changing backend JSON response shapes
changing public API/feed behavior
changing provider/materializer/canonical behavior
storing raw user/session/request identifiers
returning raw auth/session material in HTTP responses
using request params as production authority
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
- [x] Defines the next production session source contract-test PR.

## Validation

This design PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_production_session_source_design.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
