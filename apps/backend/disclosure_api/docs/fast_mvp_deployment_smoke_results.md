# Fast MVP Deployment Smoke Results

This document records Fast MVP deployment smoke results.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-fast-mvp-deployment-smoke-closeout-v1
base source: PR #311 Lock fast MVP frontend backend deployment smoke
stream: run and record Fast MVP deployment smoke results
status: smoke result record template + current automated validation evidence
```

## Important status

Live deployment smoke has not been executed in this PR because no concrete local/staging/preview deployment URL or environment was available to this GitHub-only task context.

This document therefore records:

```text
current automated/static validation evidence already available
manual smoke fields that must be filled when a real environment is available
pass/fail criteria for the final deployment smoke close-out
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

## Manual smoke environment record

Fill this section when a real deployment target is available.

```text
Smoke date:
Smoke executor:
Environment type: local / staging / preview / production-like preview
Frontend URL:
Backend/API base URL:
Branch/head:
Browser:
Backend status:
Database/fixture state:
Notes:
```

## Manual smoke result checklist

### 1. Static frontend shell

```text
Result: NOT_RUN
Evidence:
- / renders existing hero:
- Korean text renders:
- 3-card layout renders:
- latest-digest-card present:
- backend-status-card present:
- show-status button present:
- styles.css active:
- no fatal console error:
```

### 2. Frontend JS syntax

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Evidence:
- node --check apps/web/script.js: PASS in PR #309 validation
```

### 3. Backend-unavailable frontend fallback

```text
Result: NOT_RUN
Evidence:
- health fallback text shown:
- digest fallback text shown:
- page remains rendered:
- no raw JSON / stack trace / headers / cookies / tokens shown:
```

### 4. Backend health success

```text
Result: NOT_RUN
Endpoint: GET /api/health
Evidence:
- HTTP status:
- response bounded JSON:
- frontend status text:
- status button rerun:
```

### 5. Digest success

```text
Result: NOT_RUN
Endpoint: GET /api/feed/digest/latest?edition=breaking
Evidence:
- HTTP status:
- response bounded JSON:
- digest summary:
- digest items:
- alternate data.items shape:
- raw JSON not dumped:
```

### 6. Operator link

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Evidence:
- #operator-source-health-link exists
- href=/admin/source-health
- label=운영자 상태 페이지
```

### 7. Source Health missing context UI guard

```text
Result: NOT_RUN
Endpoints:
- GET /admin/source-health
- GET /admin/source-health/:source_key
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_auth_context
Evidence:
```

### 8. Source Health missing read UI guard

```text
Result: NOT_RUN
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_read_permission
Evidence:
```

### 9. Source Health read context UI

```text
Result: NOT_RUN
Expected:
- bounded list shell
- bounded detail shell
- recheck_action=disabled
- recheck_reason=read_only
Evidence:
```

### 10. Source Health read + recheck UI

```text
Result: NOT_RUN
Expected:
- bounded detail shell
- recheck_action=enabled
- recheck_target=/api/admin/source-health/:source_key/recheck
- idempotency=required
Evidence:
```

### 11. Source Health recheck API guard

```text
Result: NOT_RUN
Endpoint: POST /api/admin/source-health/:source_key/recheck
Evidence:
- no auth / body actor_permissions claim -> bounded 403:
- read-only context -> bounded 403:
- recheck context -> bounded accepted/reused response:
- unknown source -> bounded 404:
```

### 12. Source Health poll API guard

```text
Result: NOT_RUN
Endpoint: POST /api/admin/sources/:source_key/poll
Evidence:
- no poll auth -> bounded 403:
- source_health:recheck alone -> bounded 403:
- source_health:poll reaches idempotency/rate-limit gates:
- no poll UI rendered:
```

### 13. Forbidden surfaces

```text
Result: PASS_FROM_AUTOMATED_VALIDATION_FOR_STATIC_AND_ROUTE_INVENTORY
Manual evidence still needed for deployed page:
- no frontend framework bundle:
- no React/Vue/Next root marker:
- no poll UI:
- no audit UI:
- no public Source Health UI:
- no login UI introduced by Fast MVP smoke work:
- no identity provider callback route introduced by Fast MVP smoke work:
- no raw provider/auth/session/request material shown:
- no stack traces / SQL details / unbounded diagnostics shown:
```

## Current conclusion

Current conclusion before real environment execution:

```text
AUTOMATED_CONTRACT_SMOKE_PASS
MANUAL_DEPLOYMENT_SMOKE_NOT_RUN
```

The Fast MVP deployment smoke can be considered fully complete only after a real local/staging/preview environment fills the NOT_RUN sections above.

## Recommended next action

Run the manual smoke runbook against a concrete environment and update this document with:

```text
actual environment URLs
actual pass/fail results
actual screenshots or logs if available
follow-up items, if any
```

Recommended follow-up PR title:

```text
Record fast MVP deployment smoke run results
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
- [x] Records current automated validation and clearly marks real deployment smoke as not yet run.

## Validation for this results-record PR

This PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_results.md
```

No Mix test run is required for this docs-only PR unless a reviewer requests one.
