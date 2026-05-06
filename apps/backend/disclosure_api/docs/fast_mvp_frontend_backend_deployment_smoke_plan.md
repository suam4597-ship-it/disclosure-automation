# Fast MVP Frontend/Backend Deployment Smoke Plan

This document defines the Fast MVP smoke plan for the existing HTML frontend shell, backend API connection, and Source Health operator protection.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-source-health-ui-access-policy-closeout-v1
base source: PR #307 Lock source health internal UI access policy
stream: fast MVP frontend/backend deployment smoke
status: docs-only smoke plan
```

## Why this track is next

The Fast MVP direction was locked to:

```text
preserve the existing apps/web HTML/CSS/JS shell
connect backend APIs into the existing shell
keep Source Health operator pages bounded and protected
avoid frontend framework rewrites
avoid poll UI, audit UI, and public Source Health UI
avoid backend response-shape changes unless explicitly contracted
```

Recent Source Health auth/session work now locks the operator protection side:

```text
request-param actor_permissions are not production authority
SourceHealthAuthContext is authoritative when present
upstream/app auth handoff can populate SourceHealthAuthContext through bounded assigns
Source Health internal UI now requires SourceHealthAuthContext with source_health:read
missing UI context returns bounded 403 text/plain
```

The next step is to smoke the Fast MVP as a product slice: existing HTML shell + backend APIs + protected operator page.

## Smoke scope

The Fast MVP deployment smoke covers:

```text
existing public HTML shell
frontend JavaScript health check
frontend JavaScript latest digest rendering
frontend operator link
backend health API
backend latest digest API
Source Health internal UI access guard
Source Health backend recheck/poll auth guardrails
no forbidden UI surfaces
no backend response-shape drift
```

## Smoke environment assumptions

The smoke can run in any of these environments:

```text
local static HTML + same-origin mock/proxy
local Phoenix API + static HTML
staging frontend + staging backend
production-like preview frontend + staging backend
```

The smoke should prefer same-origin `/api/...` paths when possible:

```text
/ -> existing apps/web/index.html shell
/api/health -> backend health
/api/feed/digest/latest?edition=breaking -> latest digest
/admin/source-health -> protected operator UI
```

If the frontend and backend are on different hosts, use the existing JS API base URL convention:

```text
window.DISCLOSURE_API_BASE_URL
```

## Public frontend smoke

### 1. Static shell renders

Required checks:

```text
open /
existing hero renders
existing card/grid layout renders
Korean text renders correctly
no fatal console error
styles.css remains the active stylesheet
no frontend framework bundle is introduced
```

Expected source files:

```text
apps/web/index.html
apps/web/styles.css
apps/web/script.js
```

### 2. Backend health renders

Required checks:

```text
GET /api/health succeeds when backend is available
status text renders backend status
service/phase/repo details render when present
current status button re-runs health check
```

Required fallback checks:

```text
when /api/health is unavailable, page remains rendered
status text shows bounded unavailable message
no raw stack traces or transport internals are shown
```

### 3. Latest digest renders

Required checks:

```text
GET /api/feed/digest/latest?edition=breaking succeeds when backend/mock is available
digest summary renders edition/date/items count
up to 5 digest items render
payload.items shape is supported
payload.data.items shape is supported
payload.digest.items shape is supported
payload.data array shape is supported
```

Required fallback checks:

```text
when digest API is unavailable, page remains rendered
digest summary shows bounded unavailable message
digest list shows safe fallback item
raw JSON payload is not dumped into the page
```

### 4. Operator link remains minimal

Required checks:

```text
hero action row contains 설계서 보기
hero action row contains 현재 상태 확인
hero action row contains 운영자 상태 페이지
운영자 상태 페이지 href is /admin/source-health
```

Forbidden checks:

```text
no poll UI link
no audit UI link
no public Source Health UI link
no login UI introduced by this smoke track
no frontend framework introduced
```

## Backend/API smoke

### 1. Health API

Required checks:

```text
GET /api/health returns 200
response remains JSON
existing field shape remains stable
```

### 2. Digest API

Required checks:

```text
GET /api/feed/digest/latest?edition=breaking returns bounded success or bounded empty/not-found behavior according to existing API contract
frontend handles success, empty, and unavailable states
```

### 3. Existing API routes unchanged

Required checks:

```text
no new public Source Health route
no backend JSON response-shape change
no provider/materializer/canonical behavior change
```

## Source Health operator smoke

### 1. Missing context is denied on internal UI

Required checks:

```text
GET /admin/source-health without SourceHealthAuthContext -> 403 text/plain
GET /admin/source-health/:source_key without SourceHealthAuthContext -> 403 text/plain
```

Expected body:

```text
Source health access denied
state=forbidden
reason=missing_source_health_auth_context
```

### 2. Missing read permission is denied on internal UI

Required checks:

```text
SourceHealthAuthContext exists but lacks source_health:read
GET /admin/source-health/:source_key -> 403 text/plain
```

Expected body:

```text
Source health access denied
state=forbidden
reason=missing_source_health_read_permission
```

### 3. Read context can view UI

Required checks:

```text
SourceHealthAuthContext with source_health:read
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=disabled on detail
recheck_reason=read_only on detail
```

### 4. Read + recheck can see bounded recheck action

Required checks:

```text
SourceHealthAuthContext with source_health:read and source_health:recheck
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=enabled
recheck_target=/api/admin/source-health/:source_key/recheck
idempotency=required
```

### 5. Backend recheck remains protected

Required checks:

```text
POST /api/admin/source-health/:source_key/recheck without auth context -> bounded 403
body actor_permissions cannot authorize when fallback disabled
read-only context cannot authorize recheck
recheck context can authorize recheck
unknown source remains bounded 404
```

### 6. Poll remains protected and UI-hidden

Required checks:

```text
POST /api/admin/sources/:source_key/poll without poll auth -> bounded 403
source_health:recheck alone does not authorize poll
source_health:poll reaches existing idempotency/rate-limit gates
no poll UI is rendered
```

## Forbidden surface smoke

Smoke must verify absence of:

```text
React/Vue/Next.js frontend rewrite
new frontend framework bundle
poll UI
audit UI
public Source Health UI
login UI
logout UI
identity provider callback route
new public Source Health route
provider/materializer/canonical controls in UI
raw provider payloads
canonical payloads
private actor context
headers/cookies/tokens/provider credentials
stack traces / SQL details / unbounded diagnostics
```

## Recommended PR rollout

### PR A. Add Fast MVP smoke contract tests

Recommended title:

```text
Add fast MVP frontend backend smoke contract tests
```

Recommended coverage:

```text
static frontend shell expected IDs/links are present
script.js references /api/health and /api/feed/digest/latest?edition=breaking
operator link targets /admin/source-health
no forbidden Source Health public/poll/audit links in static shell
Source Health UI guard route behavior remains locked
backend route inventory remains stable
```

### PR B. Add Fast MVP manual smoke runbook

Recommended title:

```text
Add fast MVP deployment smoke runbook
```

Recommended content:

```text
local smoke steps
staging smoke steps
frontend unavailable-backend fallback steps
backend available success steps
operator access guard steps
forbidden surface checklist
```

### PR C. Fast MVP close-out

Recommended title:

```text
Lock fast MVP frontend backend deployment smoke
```

Recommended content:

```text
record smoke validation results
record known gaps
record next product track
```

## Stop conditions

Stop and re-scope if future smoke work:

```text
adds a frontend framework
redesigns the existing HTML/CSS shell
changes backend JSON response shapes without focused contract tests
adds login UI
adds identity provider callback routes
adds poll UI
adds audit UI
adds public Source Health UI
adds provider/materializer/canonical controls
uses request-param actor_permissions as production authority
returns raw provider/auth/session/request material
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
- [x] Defines the next Fast MVP smoke contract-test PR.

## Validation

This smoke-plan PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_frontend_backend_deployment_smoke_plan.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
