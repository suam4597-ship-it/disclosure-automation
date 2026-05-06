# Fast MVP Frontend/Backend Deployment Smoke Close-out

This document closes out the Fast MVP frontend/backend deployment smoke workset.

This PR is documentation-only. It records locked behavior and validation evidence from the Fast MVP deployment smoke plan, smoke contract tests, and manual smoke runbook.

## Baseline

```text
base branch: chatgpt-fast-mvp-deployment-smoke-runbook-v1
base source: PR #310 Add fast MVP deployment smoke runbook
stream: fast MVP frontend/backend deployment smoke
status: docs-only close-out
```

## Closed workset

This close-out records the completion of this sequence:

```text
PR #308 Design fast MVP frontend backend deployment smoke plan
PR #309 Add fast MVP frontend backend smoke contract tests
PR #310 Add fast MVP deployment smoke runbook
```

## Locked Fast MVP slice

The Fast MVP deployment smoke slice is locked as:

```text
existing apps/web HTML/CSS/JS shell
GET /api/health frontend integration
GET /api/feed/digest/latest?edition=breaking frontend integration
minimal operator link to /admin/source-health
Source Health internal UI access guard
Source Health backend recheck/poll authorization guardrails
forbidden UI/public surfaces remain absent
```

## Locked frontend shell behavior

Frontend shell files:

```text
apps/web/index.html
apps/web/styles.css
apps/web/script.js
```

Locked frontend expectations:

```text
existing hero renders
existing grid/card layout renders
latest digest placeholder exists
backend status placeholder exists
current status button exists
operator Source Health link exists
styles.css remains the active stylesheet
no frontend framework bundle is introduced
```

Locked operator link:

```text
id=operator-source-health-link
href=/admin/source-health
label=운영자 상태 페이지
```

## Locked frontend API behavior

Locked frontend API calls:

```text
GET /api/health
GET /api/feed/digest/latest?edition=breaking
```

Locked health fallback:

```text
백엔드 상태: 확인 불가
API 서버가 아직 연결되지 않았거나 일시적으로 응답하지 않습니다. 화면은 기존 HTML shell로 계속 표시됩니다.
```

Locked digest fallback:

```text
최신 digest를 확인할 수 없습니다.
API 서버가 아직 연결되지 않았거나 digest 데이터가 준비되지 않았습니다.
```

Locked digest response-shape support:

```text
payload.items
payload.data.items
payload.digest.items
payload.data array
```

Locked digest display constraint:

```text
render at most 5 digest items
never dump raw JSON payload into the page
```

## Locked backend/API route inventory

Smoke route inventory remains:

```text
GET /api/health
GET /api/feed/digest/latest
GET /admin/source-health
GET /admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Forbidden routes remain absent:

```text
/public/source-health
/api/public/source-health
/api/source-health
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
```

## Locked Source Health operator protection

Source Health internal UI access behavior remains:

```text
missing SourceHealthAuthContext -> 403 text/plain bounded denial
SourceHealthAuthContext without source_health:read -> 403 text/plain bounded denial
SourceHealthAuthContext with source_health:read -> bounded list/detail shell allowed
SourceHealthAuthContext with source_health:read + source_health:recheck -> bounded detail shell with recheck action enabled
query actor_permissions cannot bypass UI access guard
```

Source Health backend guard behavior remains:

```text
POST /api/admin/source-health/:source_key/recheck without auth -> bounded 403
body actor_permissions cannot authorize when fallback disabled
read-only context cannot authorize recheck
recheck context can authorize recheck
unknown source remains bounded 404
source_health:recheck alone does not authorize poll
source_health:poll reaches existing idempotency/rate-limit gates
```

## Forbidden surfaces remain absent

This workset does not add or change:

```text
frontend framework
React/Vue/Next.js shell
new routes
backend JSON response shapes
login UI
logout UI
redirect behavior
identity provider callback routes
poll UI
audit UI
public Source Health UI
provider controls
materializer controls
canonical controls
raw provider payloads
canonical payloads
private actor context
headers/cookies/tokens/provider credentials in UI or responses
stack traces / SQL details / unbounded diagnostics in UI or responses
```

## Validation evidence

PR #309 initial validation at head:

```text
3b89b8f793fe076fd2820d25f0f24a0c5feca408
```

Initial validation results:

```text
diff scope: PASS, test-only 1 file
focused test: FAIL, 22 tests, 6 failures
adjacent regression: FAIL, 53 tests, 6 failures
JS syntax: PASS, node --check apps/web/script.js
actual static shell/API/operator link scan: PASS
route/JSON response shape and UI/callback surface: PASS
```

Initial failure cause:

```text
fast_mvp_frontend_backend_smoke_contract_test.exs calculated @web_root as ../../web from apps/backend/disclosure_api/test, which resolved to apps/backend/web.
The actual frontend shell is apps/web.
```

Follow-up PR #309 head after path fix:

```text
566ac5cee6fb1902228c7c2d3c34a6552d552017
```

Final PR #309 validation:

```text
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
```

PR review:

```text
4236802599
```

## Manual smoke runbook

Manual runbook added:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_runbook.md
```

Runbook covers:

```text
automated contract smoke commands
frontend syntax smoke
static frontend shell smoke
backend-unavailable frontend fallback smoke
backend-available health and digest smoke
Source Health internal UI access smoke
Source Health recheck/poll API guard smoke
forbidden surface checklist
smoke result template
stop conditions
```

## Remaining future work

This close-out does not claim that a live production deployment has been completed. It closes the smoke planning, contract, and runbook work needed to validate one.

Remaining future work should be separate and explicit:

```text
run the manual smoke runbook against local/staging/preview deployment
record real environment URLs and results
configure deployment environment variables or proxying if needed
ship final Fast MVP release close-out after real deployment validation
```

Recommended next track:

```text
Run and record Fast MVP deployment smoke results
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
changes the existing HTML/CSS shell
adds a frontend framework
changes backend JSON response shapes without focused contract tests
adds login UI
adds identity provider callback routes
adds poll UI
adds audit UI
adds public Source Health UI
adds provider/materializer/canonical controls
trusts request-param actor_permissions as production authority
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
- [x] Records validation and closes the Fast MVP frontend/backend deployment smoke workset.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_frontend_backend_deployment_smoke_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.
