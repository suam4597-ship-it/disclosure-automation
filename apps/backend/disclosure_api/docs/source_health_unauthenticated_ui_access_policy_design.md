# Source Health Unauthenticated UI Access Policy Design

This document designs the dedicated Source Health internal UI access policy for requests that do not have a valid `SourceHealthAuthContext`.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, plugs, templates, migrations, backend response-shape changes, login UI, logout UI, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-source-health-real-upstream-auth-closeout-v1
base source: PR #303 Lock source health real upstream auth provider integration
stream: source health internal UI access policy
status: docs-only design
```

## Why this track is next

The previous workset locked the real upstream auth provider handoff path:

```text
bounded app auth assign -> upstream assigns
upstream assigns -> source_health assigns
source_health assigns -> SourceHealthAuthContext
SourceHealthAuthContext -> Source Health UI/recheck/poll authorization
```

Source Health API behavior already has bounded denial behavior when context is missing or insufficient.

The internal text UI still needs an explicit policy for requests with no valid SourceHealthAuthContext or insufficient permissions.

## Goal

Define a safe Source Health internal UI access policy without adding login UI or identity provider routes.

The policy must decide the behavior for:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

when:

```text
no SourceHealthAuthContext exists
SourceHealthAuthContext exists but lacks source_health:read
SourceHealthAuthContext has source_health:read only
SourceHealthAuthContext has source_health:recheck
SourceHealthAuthContext has source_health:poll only
```

## Non-goals

This design does not implement:

```text
login UI
logout UI
identity provider callback routes
redirect behavior
session provider integration
new routes
new controllers
new templates
backend response-shape changes for JSON APIs
poll UI
audit UI
public Source Health UI
provider/materializer/canonical behavior changes
public API/feed behavior changes
```

## Current bounded behavior

Current Source Health internal UI behavior is text/plain and bounded.

Known current behavior:

```text
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
if no permission state is requested -> recheck_action=not_rendered
if read-only context -> recheck_action=disabled
if recheck context -> recheck_action=enabled
```

The previous auth work ensures request params cannot become production authority when fallback is disabled.

## Recommended policy

### No SourceHealthAuthContext

Recommended initial behavior:

```text
GET /admin/source-health -> bounded 403 text/plain response
GET /admin/source-health/:source_key -> bounded 403 text/plain response
```

Recommended response body:

```text
Source health access denied
state=forbidden
reason=missing_source_health_auth_context
```

Rationale:

```text
keeps internal UI behavior bounded
avoids adding login UI or redirect logic
matches API denial posture more closely
prevents unauthenticated list/detail visibility
keeps backend response shape simple and text/plain for UI route only
```

### SourceHealthAuthContext exists but lacks source_health:read

Recommended behavior:

```text
GET /admin/source-health -> bounded 403 text/plain response
GET /admin/source-health/:source_key -> bounded 403 text/plain response
```

Recommended response body:

```text
Source health access denied
state=forbidden
reason=missing_source_health_read_permission
```

### source_health:read only

Recommended behavior:

```text
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=disabled
recheck_reason=read_only
```

### source_health:recheck

Recommended behavior:

```text
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=enabled
```

Policy note:

```text
source_health:recheck should be accompanied by source_health:read in role mapping.
If a malformed context has recheck without read, UI access should follow read requirement and deny.
```

### source_health:poll only

Recommended behavior:

```text
GET /admin/source-health -> bounded 403 unless source_health:read is also present
GET /admin/source-health/:source_key -> bounded 403 unless source_health:read is also present
```

Poll permission must not create poll UI.

## Route and response policy

This policy applies only to internal text UI routes:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Do not change JSON API response shapes in this UI policy work.

For UI route denials, use bounded text/plain responses only.

Do not include:

```text
raw_actor_id
raw_user_id
raw_session_id
raw_request_id
headers
cookies
tokens
provider_credentials
raw_provider_payload
canonical_payload
stack_trace
sql_details
unbounded_diagnostics
audit_event_id
```

## Redirect policy

Do not introduce redirects in this track.

Reasons:

```text
no login UI has been designed
no identity provider callback routes have been designed
redirect behavior can leak routing assumptions and complicate tests
bounded 403 is sufficient for Source Health operator protection
```

If login UX is needed later, it should be a separate design and contract-test track.

## Public surface policy

This policy must not add:

```text
public Source Health UI
poll UI
audit UI
provider controls
materializer controls
canonical controls
```

## Recommended rollout sequence

### PR A. UI access policy contract tests

Recommended title:

```text
Add source health internal UI access policy contract tests
```

Recommended coverage:

```text
missing SourceHealthAuthContext -> bounded 403 for list
missing SourceHealthAuthContext -> bounded 403 for detail
context without source_health:read -> bounded 403 for list/detail
source_health:read -> bounded list/detail with disabled recheck
source_health:recheck with read -> bounded detail with enabled recheck
source_health:poll without read -> bounded 403 for UI
request query actor_permissions cannot bypass missing context/read requirement
no poll UI, audit UI, or public Source Health UI added
```

### PR B. UI access guard helper

Recommended title:

```text
Add source health internal UI access guard
```

Recommended scope:

```text
small helper/plug for UI routes only
bounded text/plain 403 response
no redirects
no login UI
no JSON API response shape changes
focused tests only
```

### PR C. Close-out

Recommended title:

```text
Lock source health internal UI access policy
```

Recommended content:

```text
record implementation commits
record focused and adjacent regression results
record remaining login UX / IDP callback work if any
```

## Stop conditions

Stop and re-scope if future work:

```text
adds login UI in this Source Health access-policy PR
adds identity provider callback routes
adds public Source Health UI
adds poll UI
adds audit UI
changes JSON API response shapes
uses request-param actor_permissions as production authority
returns raw auth/session/request material
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
- [x] Defines the next UI access policy contract-test PR.

## Validation

This design PR should change only:

```text
apps/backend/disclosure_api/docs/source_health_unauthenticated_ui_access_policy_design.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
