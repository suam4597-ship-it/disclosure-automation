# Fast MVP Deployment Smoke Results

This document records Fast MVP deployment smoke results.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-fast-mvp-deployment-smoke-closeout-v1
base source: PR #311 Lock fast MVP frontend backend deployment smoke
stream: run and record Fast MVP deployment smoke results
status: automated validation + local staging-like smoke evidence recorded
```

## Important Status

External staging/preview deployment smoke has not been executed in this PR because no concrete deployed URL was available.

Deployment availability classification:

```text
deployment availability: LOCAL_PREVIEW_ONLY
reason:
- apps/web is static-deployable and has apps/web/vercel.json, but no Vercel project metadata, token, or environment was available locally.
- GitHub Pages deployment workflow exists, but it targets the github-pages environment from main/phase0-foundation and is not a PR-specific staging/preview URL generator.
- Triggering the GitHub Pages workflow from this verification would mutate an external deployment surface rather than create an isolated preview, so it was not run.
- Phoenix backend can run locally and in CI smoke, but no external staging backend service config or required deployment credentials were available.
```

Local staging-like smoke was executed with:

```text
environment type: local staging-like static server + local mock backend
frontend static URL: http://127.0.0.1:8781/
frontend + same-origin mock backend URL: http://127.0.0.1:8782/
backend/API base URL: http://127.0.0.1:8782
```

This document therefore records:

```text
current automated/static validation evidence
local staging-like smoke evidence
external staging/preview smoke fields that must be filled when a real deployment URL is available
```

## Locked Fast MVP Slice Under Validation

```text
existing apps/web HTML/CSS/JS shell
GET /api/health frontend integration
GET /api/feed/digest/latest?edition=breaking frontend integration
minimal operator link to /admin/source-health
Source Health internal UI access guard
Source Health backend recheck/poll authorization guardrails
forbidden UI/public surfaces remain absent
```

## Current Automated/Static Validation Evidence

Latest Fast MVP smoke validation executed for this results record:

```text
head: 28673a8e0a364691a4b711f6c31876e8b63f9c28
diff scope: PASS, docs-only 1 file
focused test: PASS, 22 tests, 0 failures
adjacent regression: PASS, 53 tests, 0 failures
JS syntax: PASS, node --check apps/web/script.js
static shell contract: PASS
health API reference: PASS
digest API reference: PASS
operator link: PASS
forbidden surfaces: PASS
route inventory: PASS
route/JSON response shape: PASS
UI/callback surface: PASS
```

Fast MVP smoke runbook added in PR #310:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_runbook.md
```

Fast MVP smoke close-out added in PR #311:

```text
apps/backend/disclosure_api/docs/fast_mvp_frontend_backend_deployment_smoke_closeout.md
```

## Smoke Environment Record

```text
Smoke date: 2026-05-06
Smoke executor: Codex local verification
Environment type: local staging-like static server + local mock backend
Frontend URL: http://127.0.0.1:8781/ and http://127.0.0.1:8782/
Backend/API base URL: http://127.0.0.1:8782
Branch/head: chatgpt-fast-mvp-deployment-smoke-results-v1 / 28673a8e0a364691a4b711f6c31876e8b63f9c28
Browser: NOT_RUN, Browser Use Node REPL requires Node >= 22.22.0; local machine resolved Node v20.13.1
Backend status: local mock backend responded with bounded /api/health and digest JSON
Database/fixture state: automated ExUnit Source Health smoke used local test database; external deployed database not used
Notes: no external staging/preview URL was available; external staging/preview smoke remains NOT_RUN
```

## Smoke Result Checklist

### 1. Static Frontend Shell

```text
Result: PASS_LOCAL_STATIC
Evidence:
- / returns HTTP 200 from local static server
- html lang=ko present
- hero class present
- card count=3
- latest-digest-card present
- digest-summary present
- digest-items present
- backend-status-card present
- status-text present
- status-details present
- show-status button present
- operator-source-health-link present
- styles.css returns HTTP 200
- script.js returns HTTP 200
- browser visual smoke: NOT_RUN, Browser Use Node REPL requires Node >= 22.22.0 but local resolved Node v20.13.1
```

### 2. Frontend JS Syntax

```text
Result: PASS
Evidence:
- node --check apps/web/script.js: PASS
```

### 3. Backend-Unavailable Frontend Fallback

```text
Result: PASS_LOCAL_CONTRACT
Evidence:
- static-only /api/health returned HTTP 404
- script.js keeps renderHealthUnavailable fallback path
- script.js keeps renderDigestUnavailable fallback path
- page shell remains available from local static server
- no stack trace / cookies / tokens / provider secret / canonical payload fragments found in static shell
```

### 4. Backend Health Success

```text
Result: PASS_LOCAL_MOCK
Endpoint: GET /api/health
Evidence:
- HTTP status: 200 from local mock backend
- response bounded JSON: status, service, phase, repo, count
- status=ok
- service=disclosure_automation
- repo=suam4597-ship-it/disclosure-automation
- status button rerun evidence: mock health count changed from 1 to 2 across repeated calls
```

### 5. Digest Success

```text
Result: PASS_LOCAL_MOCK
Endpoint: GET /api/feed/digest/latest?edition=breaking
Evidence:
- HTTP status: 200 from local mock backend
- response bounded JSON: edition, digest_date, items
- edition=breaking
- digest_date=2026-05-06
- digest items: 2 top-level items in first response
- alternate data.items shape: PASS, second response returned data.items with display_title="data.items 이벤트" and region_code=KR
- raw JSON not dumped by static shell contract
```

### 6. Operator Link

```text
Result: PASS_LOCAL_STATIC_AND_AUTOMATED_VALIDATION
Evidence:
- #operator-source-health-link exists
- href=/admin/source-health
```

### 7. Source Health Missing Context UI Guard

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Endpoints:
- GET /admin/source-health
- GET /admin/source-health/:source_key
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_auth_context
Evidence:
- covered by focused and adjacent Source Health internal UI access guard tests
```

### 8. Source Health Missing Read UI Guard

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Expected:
- 403 text/plain
- Source health access denied
- state=forbidden
- reason=missing_source_health_read_permission
Evidence:
- covered by focused and adjacent Source Health internal UI access guard tests
```

### 9. Source Health Read Context UI

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Expected:
- bounded list shell
- bounded detail shell
- recheck_action=disabled
- recheck_reason=read_only
Evidence:
- covered by focused and adjacent Source Health internal UI tests
```

### 10. Source Health Read + Recheck UI

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Expected:
- bounded detail shell
- recheck_action=enabled
- recheck_target=/api/admin/source-health/:source_key/recheck
- idempotency=required
Evidence:
- covered by focused and adjacent Source Health internal UI recheck tests
```

### 11. Source Health Recheck API Guard

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Endpoint: POST /api/admin/source-health/:source_key/recheck
Evidence:
- no auth / body actor_permissions claim -> bounded 403
- read-only context -> bounded 403
- recheck context -> bounded accepted/reused response
- unknown source -> bounded 404
- covered by focused and adjacent Source Health authorization tests
```

### 12. Source Health Poll API Guard

```text
Result: PASS_FROM_AUTOMATED_VALIDATION
Endpoint: POST /api/admin/sources/:source_key/poll
Evidence:
- no poll auth -> bounded 403
- source_health:recheck alone -> bounded 403
- source_health:poll reaches idempotency/rate-limit gates
- no poll UI rendered
- covered by focused and adjacent Source Health poll authorization tests
```

### 13. Forbidden Surfaces

```text
Result: PASS_LOCAL_STATIC_AND_AUTOMATED_VALIDATION
Evidence:
- no frontend framework bundle
- no React/Vue/Next root marker
- no poll UI
- no audit UI
- no public Source Health UI
- no login UI introduced by Fast MVP smoke work
- no redirect introduced by Fast MVP smoke work
- no identity provider callback route introduced by Fast MVP smoke work
- no raw provider/auth/session/request material shown
- no stack traces / SQL details / unbounded diagnostics shown
- backend route/JSON response shape unchanged
```

## Current Conclusion

Current conclusion after local staging-like smoke and before external staging/preview execution:

```text
LOCAL_SMOKE_PASS
LOCAL_STAGING_LIKE_SMOKE_PASS
AUTOMATED_CONTRACT_SMOKE_PASS
STAGING_PREVIEW_DEPLOYMENT_SMOKE_NOT_RUN
BROWSER_VISUAL_SMOKE_NOT_RUN_NODE_REPL_VERSION
```

The Fast MVP deployment smoke has local staging-like evidence, but external staging/preview smoke can be considered fully complete only after a concrete deployed URL is available.

## Recommended Next Action

If a concrete deployed URL becomes available, run the manual smoke runbook against that environment and update this document with:

```text
actual external environment URLs
actual external pass/fail results
actual screenshots or logs if available
follow-up items, if any
```

Recommended follow-up PR title:

```text
Record fast MVP external deployment smoke run results
```

## Stop Conditions

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

## Fast MVP Drift Check

- [x] Keeps existing HTML/CSS shell unchanged.
- [x] Does not introduce React/Vue/Next.js or another frontend framework.
- [x] Uses existing backend routes; adds no routes.
- [x] Does not add poll UI.
- [x] Does not add audit UI.
- [x] Does not add public Source Health UI.
- [x] Does not change provider/materializer/canonical behavior.
- [x] Does not change backend JSON response shapes.
- [x] Keeps Source Health auth/session work limited to operator protection.
- [x] Records automated validation and local staging-like smoke evidence.
- [x] Clearly marks external staging/preview smoke as not yet run.

## Validation For This Results-Record PR

This PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_results.md
```

Mix validation executed for this PR:

```text
focused smoke: PASS, 22 tests, 0 failures
adjacent smoke regression: PASS, 53 tests, 0 failures
JS syntax: PASS
```
