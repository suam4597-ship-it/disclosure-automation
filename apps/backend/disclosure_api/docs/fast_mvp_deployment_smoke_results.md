# Fast MVP Deployment Smoke Results

This document records Fast MVP deployment smoke results.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-fast-mvp-deployment-smoke-closeout-v1
base source: PR #311 Lock fast MVP frontend backend deployment smoke
stream: run and record Fast MVP deployment smoke results
status: local smoke results recorded; staging/preview smoke not run because no URL was provided
```

## Important status

Local smoke has been executed with:

```text
local automated tests
local static server
local mock backend
```

A real staging/preview deployment smoke has not been executed because no concrete staging/preview URL was available in this task context.

Current conclusion:

```text
LOCAL_SMOKE_PASS
AUTOMATED_CONTRACT_SMOKE_PASS
STAGING_PREVIEW_DEPLOYMENT_SMOKE_NOT_RUN
```

## Locked Fast MVP slice under validation

```text
existing apps/web HTML/CSS/JS shell
GET /api/health frontend integration
GET /api/feed/digest/latest?edition=breaking frontend integration
minimal operator link to /admin/source-health
Source Health internal UI access guard
Source Health backend recheck/poll authorization guardrails
forbidden UI/public surfaces remain absent
```

## Current automated/static validation evidence

Latest Fast MVP smoke contract validation recorded from PR #309:

```text
head: 566ac5cee6fb1902228c7c2d3c34a6552d552017
diff scope: PASS, test-only 1 file
focused test: PASS, 22 tests, 0 failures
adjacent regression: PASS, 53 tests, 0 failures
JS syntax: PASS, node --check apps/web/script.js
path fix: PASS
static shell contract: PASS
health API reference: PASS
digest API reference: PASS
operator link: PASS
forbidden surfaces: PASS
route inventory: PASS
route/JSON response shape: PASS
UI/callback surface: PASS
PR review: 4236802599
```

Fast MVP smoke runbook added in PR #310:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_runbook.md
```

Fast MVP smoke close-out added in PR #311:

```text
apps/backend/disclosure_api/docs/fast_mvp_frontend_backend_deployment_smoke_closeout.md
```

## Local smoke environment record

```text
Smoke date: 2026-05-06
Smoke executor: Codex/local validation
Environment type: local automated tests + local static server + local mock backend
Frontend URL: http://127.0.0.1:8781/, http://127.0.0.1:8782/
Backend/API base URL: local mock http://127.0.0.1:8782
Branch/head: chatgpt-fast-mvp-deployment-smoke-results-v1 / 28673a8e0a364691a4b711f6c31876e8b63f9c28
Browser: browser visual smoke NOT_RUN due to Browser Use Node requirement issue
Backend status: local mock backend available for health/digest checks
Database/fixture state: not required for local mock frontend checks; Source Health guard verified by automated tests
Notes: real staging/preview URL was not provided, so staging/preview smoke remains NOT_RUN
```

## Local smoke result checklist

### 1. Static frontend shell

```text
Result: PASS_LOCAL_STATIC
Evidence:
- file/static HTTP checks passed
- / renders existing shell by static file checks
- Korean text present in index.html
- 3-card layout present in index.html
- latest-digest-card present
- backend-status-card present
- show-status button present
- styles.css active via linked stylesheet
- browser visual smoke: NOT_RUN due to Browser Use Node requirement issue
```

### 2. Frontend JS syntax

```text
Result: PASS
Evidence:
- node --check apps/web/script.js: PASS
```

### 3. Backend-unavailable frontend fallback

```text
Result: PASS_LOCAL_CONTRACT
Evidence:
- static-only /api/health returned 404
- JS fallback path preserved
- health fallback copy exists: 백엔드 상태: 확인 불가
- digest fallback copy exists: 최신 digest를 확인할 수 없습니다.
- page remains protected by static shell contract
- raw JSON / stack trace / headers / cookies / tokens are not expected to be shown by fallback path
```

### 4. Backend health success

```text
Result: PASS_LOCAL_MOCK
Endpoint: GET /api/health
Evidence:
- local mock /api/health returned status=ok
- service=disclosure_automation
- repo details displayed/preserved by smoke
- frontend status path confirmed through local mock
```

### 5. Digest success

```text
Result: PASS_LOCAL_MOCK
Endpoint: GET /api/feed/digest/latest?edition=breaking
Evidence:
- local mock returned edition=breaking
- digest_date=2026-05-06
- 2 items returned
- alternate data.items shape returned data.items 이벤트 / KR
- raw JSON not dumped by contract
```

### 6. Operator link

```text
Result: PASS
Evidence:
- #operator-source-health-link exists
- href=/admin/source-health
- label=운영자 상태 페이지
```

### 7. Source Health missing context UI guard

```text
Result: PASS_AUTOMATED_TESTS
Endpoints:
- GET /admin/source-health
- GET /admin/source-health/:source_key
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_auth_context
Evidence:
- verified by automated Source Health UI access guard tests
```

### 8. Source Health missing read UI guard

```text
Result: PASS_AUTOMATED_TESTS
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_read_permission
Evidence:
- verified by automated Source Health UI access guard tests
```

### 9. Source Health read context UI

```text
Result: PASS_AUTOMATED_TESTS
Expected:
- bounded list shell
- bounded detail shell
- recheck_action=disabled
- recheck_reason=read_only
Evidence:
- verified by automated Source Health UI tests
```

### 10. Source Health read + recheck UI

```text
Result: PASS_AUTOMATED_TESTS
Expected:
- bounded detail shell
- recheck_action=enabled
- recheck_target=/api/admin/source-health/:source_key/recheck
- idempotency=required
Evidence:
- verified by automated Source Health UI tests
```

### 11. Source Health recheck API guard

```text
Result: PASS_AUTOMATED_TESTS
Endpoint: POST /api/admin/source-health/:source_key/recheck
Evidence:
- no auth / body actor_permissions claim -> bounded 403 verified by automated tests
- read-only context -> bounded 403 verified by automated tests
- recheck context -> bounded accepted/reused response verified by automated tests
- unknown source -> bounded 404 verified by automated tests
```

### 12. Source Health poll API guard

```text
Result: PASS_AUTOMATED_TESTS
Endpoint: POST /api/admin/sources/:source_key/poll
Evidence:
- no poll auth -> bounded 403 verified by automated tests
- source_health:recheck alone -> bounded 403 verified by automated tests
- source_health:poll reaches idempotency/rate-limit gates verified by automated tests
- no poll UI rendered by route/static inventory
```

### 13. Forbidden surfaces

```text
Result: PASS_LOCAL_AND_AUTOMATED
Evidence:
- no frontend framework/login/callback/poll UI/audit UI/public Source Health UI added
- no frontend framework references found by smoke contract/static checks
- no forbidden Source Health public/poll/audit links found
- runtime/router/frontend shell diff empty against base except docs result update
- route/JSON response shape unchanged
- no new blocking warning identified
```

## Current conclusion

Current conclusion after local smoke execution:

```text
LOCAL_SMOKE_PASS
AUTOMATED_CONTRACT_SMOKE_PASS
STAGING_PREVIEW_DEPLOYMENT_SMOKE_NOT_RUN
```

The Fast MVP deployment smoke can be considered locally validated. It is not yet fully staging/preview validated because no real staging/preview URL was provided.

## Recommended next action

Run the manual smoke runbook against a concrete staging or preview environment and update this document with:

```text
actual staging/preview frontend URL
actual staging/preview backend/API base URL
actual pass/fail results
actual screenshots or logs if available
follow-up items, if any
```

Recommended follow-up PR title:

```text
Record fast MVP staging deployment smoke run results
```

## Stop conditions

Stop and re-scope if recording smoke results requires:

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
- [x] Records local smoke validation and clearly marks staging/preview smoke as not yet run.

## Validation for this results-record PR

This PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_results.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
