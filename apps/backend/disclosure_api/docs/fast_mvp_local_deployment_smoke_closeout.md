# Fast MVP Local Deployment Smoke Close-out

This document closes out the local Fast MVP deployment smoke result recording step after the latest PR #312 results-record updates.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
base branch: chatgpt-fast-mvp-deployment-smoke-closeout-v1
base source: PR #312 Add fast MVP deployment smoke results record, squash-merged into this branch
base/head source after PR #312 merge: 16a07b03ec4c80fa7ea905480e74d6e4e5f5a1df
stream: Fast MVP local deployment smoke result close-out
status: docs-only close-out refreshed after PR #312 merge
```

## Why this close-out exists

The first local close-out PR was opened before the final PR #312 results-record updates landed.

```text
previous close-out PR: #313
previous #313 base/merge-base: 5b2ef7c09ef932c2924701495cc52cd9c76a4767
latest PR #312 head before merge: 42a03951af92544f3730832f0fd03052d8c03dcc
PR #312 squash merge commit now used as this close-out base: 16a07b03ec4c80fa7ea905480e74d6e4e5f5a1df
reason for v3: #313 diverged from latest #312; #314 was replaced after #312 was squash-merged so this PR carries only the local close-out doc on top of the merged results record
```

This close-out preserves the same docs-only scope but bases the close-out on the merged PR #312 results record.

## Closed workset

This close-out records the completion of the local smoke result recording sequence:

```text
PR #308 Design fast MVP frontend backend deployment smoke plan
PR #309 Add fast MVP frontend backend smoke contract tests
PR #310 Add fast MVP deployment smoke runbook
PR #311 Lock fast MVP frontend backend deployment smoke
PR #312 Add fast MVP deployment smoke results record
```

## Current final local conclusion

```text
LOCAL_SMOKE_PASS
LOCAL_STAGING_LIKE_SMOKE_PASS
AUTOMATED_CONTRACT_SMOKE_PASS
STAGING_PREVIEW_DEPLOYMENT_SMOKE_NOT_RUN
BROWSER_VISUAL_SMOKE_NOT_RUN_NODE_REPL_VERSION
```

The Fast MVP slice is locally validated through automated contract tests, static frontend checks, local static server checks, and local mock backend checks.

A real external staging/preview smoke has not been run because no concrete staging/preview deployment URL or external backend/API base URL was available.

## Local smoke evidence recorded in PR #312

PR #312 result document:

```text
apps/backend/disclosure_api/docs/fast_mvp_deployment_smoke_results.md
```

PR #312 merge source now used by this close-out:

```text
source PR: #312 Add fast MVP deployment smoke results record
merged base commit: 16a07b03ec4c80fa7ea905480e74d6e4e5f5a1df
pre-merge results branch: chatgpt-fast-mvp-deployment-smoke-results-v1
pre-merge results branch head: 42a03951af92544f3730832f0fd03052d8c03dcc
```

Recorded smoke environment:

```text
environment type: local staging-like static server + local mock backend
frontend static URL: http://127.0.0.1:8781/
frontend + same-origin mock backend URL: http://127.0.0.1:8782/
backend/API base URL: http://127.0.0.1:8782
smoke date: 2026-05-06
executor: Codex local verification
```

Deployment availability classification recorded in PR #312:

```text
deployment availability: LOCAL_PREVIEW_ONLY
reason:
- apps/web is static-deployable and has apps/web/vercel.json, but no Vercel project metadata, token, or environment was available locally.
- GitHub Pages deployment workflow exists, but it targets the github-pages environment from main/phase0-foundation and is not a PR-specific staging/preview URL generator.
- Triggering the GitHub Pages workflow from this verification would mutate an external deployment surface rather than create an isolated preview, so it was not run.
- Phoenix backend can run locally and in CI smoke, but no external staging backend service config or required deployment credentials were available.
```

## Locked local smoke results

```text
focused smoke: PASS, 22 tests, 0 failures
adjacent smoke regression: PASS, 53 tests, 0 failures
JS syntax: PASS, node --check apps/web/script.js
static shell contract: PASS
static frontend shell: PASS by file/static HTTP checks
backend unavailable fallback: PASS_LOCAL_CONTRACT
backend health success: PASS_LOCAL_MOCK
digest success: PASS_LOCAL_MOCK
digest alternate data.items shape: PASS_LOCAL_MOCK
status button rerun: PASS_LOCAL_CONTRACT
operator link: PASS
Source Health missing context UI guard: PASS via automated tests
Source Health missing read UI guard: PASS via automated tests
Source Health read context UI: PASS via automated tests
Source Health read + recheck UI: PASS via automated tests
Source Health recheck API guard: PASS via automated tests
Source Health poll API guard: PASS via automated tests
forbidden surfaces: PASS
route/JSON response shape: PASS
UI/callback surface: PASS
cleanup/worktree: PASS
```

Browser visual smoke status:

```text
NOT_RUN because Browser Use Node REPL requires Node >= 22.22.0 but the local machine resolved Node v20.13.1.
Static file and static HTTP checks passed.
```

External staging/preview status:

```text
NOT_RUN because no concrete staging/preview frontend URL or API base URL was available.
```

## Locked Fast MVP behavior

The locally validated Fast MVP slice remains:

```text
existing apps/web HTML/CSS/JS shell
GET /api/health frontend integration
GET /api/feed/digest/latest?edition=breaking frontend integration
minimal operator link to /admin/source-health
Source Health internal UI access guard
Source Health backend recheck/poll authorization guardrails
forbidden UI/public surfaces remain absent
```

## Surfaces confirmed unchanged

The local smoke result confirms no change to:

```text
existing HTML/CSS shell
frontend framework usage
backend JSON response shapes
route inventory
login UI
redirect behavior
identity provider callback routes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical behavior
request-param actor_permissions production authority rules
raw provider/auth/session/request material exposure
```

## Remaining future work

The remaining work requires a concrete deployment URL.

Recommended next PR when an environment is available:

```text
Record fast MVP external deployment smoke run results
```

Required inputs:

```text
staging/preview frontend URL
staging/preview backend/API base URL
smoke execution date
executor
actual pass/fail results
logs or screenshots if available
follow-up items, if any
```

## External deployment decision points

The current local close-out intentionally does not mutate any external deployment surface.

```text
GitHub Pages shared surface: do not update or dispatch without explicit user approval
Vercel preview: cannot proceed without token/project/org metadata and required environment
external backend staging: cannot proceed without DATABASE_URL, SECRET_KEY_BASE, PHX_HOST, hosting target, and deployment credentials
local-only close-out: complete for current evidence level
```

## Stop conditions for future work

Stop and re-scope if future deployment smoke work requires:

```text
changing the existing HTML/CSS shell
adding a frontend framework
changing backend JSON response shapes without focused contract tests
adding login UI
adding identity provider callback routes
adding poll UI
adding audit UI
adding public Source Health UI
adding provider/materializer/canonical controls
trusting request-param actor_permissions as production authority
returning raw provider/auth/session/request material
adding duplicate controller modules
mutating shared GitHub Pages without explicit approval and rollback plan
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
- [x] Records local deployment smoke evidence and explicitly leaves staging/preview smoke pending.
- [x] Records why the prior close-out PRs diverged/rebased and refreshes this close-out from the merged PR #312 base.

## Validation for this close-out PR

This close-out PR should change only:

```text
apps/backend/disclosure_api/docs/fast_mvp_local_deployment_smoke_closeout.md
```

No Mix test run is required for this docs-only close-out PR unless a reviewer requests one.

Suggested diff check:

```powershell
git diff --stat chatgpt-fast-mvp-deployment-smoke-closeout-v1...HEAD
```

Expected changed file:

```text
apps/backend/disclosure_api/docs/fast_mvp_local_deployment_smoke_closeout.md
```
