# Fast MVP Deployment Smoke Runbook

This runbook defines manual smoke steps for the Fast MVP frontend/backend deployment slice.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-fast-mvp-smoke-contract-tests-v1
base source: PR #309 Add fast MVP frontend backend smoke contract tests
stream: fast MVP deployment smoke runbook
status: docs-only runbook
```

## Purpose

Use this runbook to manually validate that the Fast MVP product slice still works after deployment or preview setup.

Fast MVP slice:

```text
existing apps/web HTML/CSS/JS shell
GET /api/health frontend integration
GET /api/feed/digest/latest?edition=breaking frontend integration
minimal operator link to /admin/source-health
Source Health internal UI access guard
Source Health backend recheck/poll authorization guardrails
forbidden UI/public surfaces remain absent
```

## Preconditions

Recommended local tools:

```text
Git
Elixir/Mix for backend tests
Node.js for script syntax check
browser with devtools
optional local static file server
optional same-origin proxy/mock server
```

Repo root:

```text
suam4597-ship-it/disclosure-automation
```

Important files:

```text
apps/web/index.html
apps/web/styles.css
apps/web/script.js
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
```

## Automated contract smoke

Run from:

```text
apps/backend/disclosure_api
```

Focused:

```powershell
$env:MIX_ENV='test'; mix.bat test test/fast_mvp_frontend_backend_smoke_contract_test.exs test/source_health_internal_ui_access_guard_test.exs test/source_health_internal_ui_access_policy_contract_test.exs
```

Adjacent Fast MVP / Source Health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/fast_mvp_frontend_backend_smoke_contract_test.exs test/source_health_internal_ui_access_guard_test.exs test/source_health_internal_ui_access_policy_contract_test.exs test/source_health_internal_ui_route_inventory_test.exs test/source_health_upstream_auth_provider_adapter_route_wiring_test.exs test/source_health_upstream_auth_handoff_route_wiring_test.exs test/source_health_production_auth_context_route_wiring_test.exs test/source_health_recheck_authorization_test.exs test/source_health_poll_authorization_contract_test.exs
```

Expected:

```text
all tests pass
no runtime file changes required
no JSON response-shape changes
no frontend shell changes
```

## Frontend syntax smoke

From repo root:

```powershell
node --check apps/web/script.js
```

Expected:

```text
no syntax errors
```

## Static frontend shell smoke

Open:

```text
apps/web/index.html
```

or serve `apps/web` with a simple static server.

Required visual checks:

```text
hero is visible
Korean text renders correctly
three cards render
최근 피드 요약 card exists
현재 포함된 핵심 자산 card exists
백엔드 연결 상태 card exists
설계서 보기 action exists
현재 상태 확인 button exists
운영자 상태 페이지 link exists
```

Required DOM/attribute checks:

```text
#latest-digest-card exists
#digest-summary exists
#digest-items exists
#backend-status-card exists
#status-text exists
#status-details exists
#show-status exists
#operator-source-health-link exists
#operator-source-health-link href is /admin/source-health
```

Forbidden checks:

```text
no React/Vue/Next bundle or root marker
no poll UI link
no audit UI link
no public Source Health UI link
no login UI introduced by this Fast MVP smoke track
```

## Frontend backend-unavailable smoke

Run the static page without a backend or without API proxy.

Expected health fallback:

```text
백엔드 상태: 확인 불가
API 서버가 아직 연결되지 않았거나 일시적으로 응답하지 않습니다. 화면은 기존 HTML shell로 계속 표시됩니다.
```

Expected digest fallback:

```text
최신 digest를 확인할 수 없습니다.
API 서버가 아직 연결되지 않았거나 digest 데이터가 준비되지 않았습니다.
```

Required checks:

```text
page remains rendered
no fatal console error
raw JSON is not dumped into the page
stack traces are not shown
headers/cookies/tokens are not shown
```

## Frontend backend-available smoke

Use a same-origin backend/proxy/mock so the frontend can call:

```text
GET /api/health
GET /api/feed/digest/latest?edition=breaking
```

### Health success expectation

Example success payload:

```json
{
  "status": "ok",
  "service": "disclosure_automation",
  "phase": 0,
  "repo": "suam4597-ship-it/disclosure-automation"
}
```

Expected UI:

```text
백엔드 상태: ok
service=disclosure_automation · phase=0 · repo=suam4597-ship-it/disclosure-automation
```

### Digest success expectation

Example success payload:

```json
{
  "edition": "breaking",
  "digest_date": "2026-05-06",
  "items": [
    {
      "title": "테스트 이벤트 1",
      "region_code": "US",
      "source_key": "test_source",
      "published_at": "2026-05-06T00:00:00Z"
    },
    {
      "headline": "테스트 이벤트 2",
      "region": "JP",
      "provider": "test_provider",
      "date": "2026-05-06"
    }
  ]
}
```

Expected UI:

```text
edition=breaking · digest=2026-05-06 · items=2
테스트 이벤트 1
테스트 이벤트 2
```

Also verify at least one alternate digest shape when using mocks:

```json
{
  "data": {
    "edition": "breaking",
    "digest_date": "2026-05-06",
    "items": [
      { "display_title": "data.items 이벤트", "region_code": "KR" }
    ]
  }
}
```

Expected:

```text
data.items 이벤트 · KR
```

Button check:

```text
click 현재 상태 확인
health request runs again
digest request runs again
page remains rendered
```

## Backend API smoke

### Health route

```text
GET /api/health
```

Expected:

```text
200 JSON
bounded response
no stack trace
no headers/cookies/tokens
```

### Latest digest route

```text
GET /api/feed/digest/latest?edition=breaking
```

Expected:

```text
bounded JSON success, empty, or existing not-found behavior according to current API contract
frontend handles success and unavailable states
no raw provider payload exposed
```

## Source Health internal UI smoke

### Missing context

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Expected:

```text
403 text/plain
Source health access denied
state=forbidden
reason=missing_source_health_auth_context
```

### Missing read permission

Use a request with SourceHealthAuthContext but without `source_health:read`.

Expected:

```text
403 text/plain
Source health access denied
state=forbidden
reason=missing_source_health_read_permission
```

### Read context

Use SourceHealthAuthContext with:

```text
source_health:read
```

Expected:

```text
GET /admin/source-health -> bounded list shell
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=disabled
recheck_reason=read_only
```

### Read + recheck context

Use SourceHealthAuthContext with:

```text
source_health:read
source_health:recheck
```

Expected:

```text
GET /admin/source-health/:source_key -> bounded detail shell
recheck_action=enabled
recheck_target=/api/admin/source-health/:source_key/recheck
idempotency=required
```

### Query bypass check

```text
GET /admin/source-health/:source_key?actor_permissions=source_health:recheck
```

without SourceHealthAuthContext.

Expected:

```text
403 text/plain
reason=missing_source_health_auth_context
```

## Source Health API guard smoke

### Recheck without auth

```text
POST /api/admin/source-health/:source_key/recheck
```

with body claiming:

```json
{ "actor_permissions": ["source_health:recheck"] }
```

Expected:

```text
403 JSON
source health recheck not allowed
```

### Recheck read-only

SourceHealthAuthContext:

```text
source_health:read
```

Expected:

```text
403 JSON
source health recheck not allowed
```

### Recheck allowed

SourceHealthAuthContext:

```text
source_health:recheck
```

Expected:

```text
202 JSON or reused bounded response according to current idempotency state
```

### Poll not allowed for recheck-only

SourceHealthAuthContext:

```text
source_health:recheck
```

Expected:

```text
403 JSON
source poll not allowed
```

### Poll operator reaches existing gates

SourceHealthAuthContext:

```text
source_health:poll
```

With missing idempotency key, expected:

```text
409 JSON
missing_idempotency_key
```

## Forbidden surface checklist

The smoke fails if any of these appear:

```text
new frontend framework
React root marker
Vue root marker
Next.js bundle marker
poll UI
audit UI
public Source Health UI
login UI
redirect behavior introduced by Source Health guard
identity provider callback route
new public Source Health route
provider/materializer/canonical UI controls
raw provider payload
canonical payload
private actor context
headers/cookies/tokens/provider credentials in UI or responses
stack traces / SQL details / unbounded diagnostics in UI or responses
```

## Smoke result template

Use this template when recording validation:

```text
Result:
- branch/head:
- frontend static shell:
- JS syntax:
- backend unavailable fallback:
- backend health success:
- digest success:
- digest alternate shape:
- status button rerun:
- operator link:
- Source Health missing context:
- Source Health missing read:
- Source Health read context:
- Source Health read+recheck context:
- recheck API guard:
- poll API guard:
- forbidden surfaces:
- route/JSON response shape:
- warnings:
- cleanup/worktree:
- follow-up needed:
```

## Stop conditions

Stop and re-scope if smoke work requires:

```text
changing the existing HTML/CSS shell
adding a frontend framework
changing backend JSON response shapes
adding login UI
adding identity provider callback routes
adding poll UI
adding audit UI
adding public Source Health UI
adding provider/materializer/canonical controls
trusting request-param actor_permissions as production authority
returning raw provider/auth/session/request material
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
- [x] Does not change backend JSON response shapes.
- [x] Keeps Source Health auth/session work limited to operator protection.
- [x] Defines the final Fast MVP smoke close-out PR after validation.

## Validation

This runbook PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_runbook.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
