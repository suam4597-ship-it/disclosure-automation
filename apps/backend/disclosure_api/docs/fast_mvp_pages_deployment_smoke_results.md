# Fast MVP GitHub Pages Deployment Smoke Results

This document records the GitHub Pages shared-surface deployment smoke status for the Fast MVP shell.

This PR is documentation-only. It does not add runtime code, tests, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
source branch: phase0-foundation
source update PR: #316 Deploy Fast MVP shell to GitHub Pages source
source update merge commit: c48583f38204c408f744fe8a888e97bbe6c23b3e
smoke record branch: chatgpt-fast-mvp-pages-smoke-results-v1
smoke date: 2026-05-07 Asia/Seoul
executor: ChatGPT GitHub connector + external URL fetch attempt
```

## Deployment Source Status

The shared GitHub Pages source branch has been updated to the latest Fast MVP static shell.

```text
GITHUB_PAGES_SOURCE_UPDATED
```

The updated source branch now contains:

```text
apps/web/index.html
apps/web/script.js
apps/web/styles.css
.github/workflows/deploy-pages-phase0.yml
```

The Pages workflow deploys `apps/web` into the Pages artifact:

```text
workflow: .github/workflows/deploy-pages-phase0.yml
branches: phase0-foundation, main
paths: apps/web/**, .github/workflows/deploy-pages-phase0.yml
artifact source: apps/web/ copied into site/
environment: github-pages
```

## Source-Level Smoke Evidence

### Static shell markup

```text
Result: PASS_SOURCE
Evidence:
- apps/web/index.html exists on phase0-foundation after PR #316 merge.
- html lang=ko is present.
- existing hero shell remains present.
- latest-digest-card is present.
- digest-summary is present.
- digest-items is present.
- backend-status-card is present.
- status-text is present.
- status-details is present.
- show-status button is present.
- operator-source-health-link is present.
- operator link href remains /admin/source-health.
```

### Frontend API wiring

```text
Result: PASS_SOURCE
Evidence:
- apps/web/script.js exists on phase0-foundation after PR #316 merge.
- API_BASE_URL remains bounded to window.DISCLOSURE_API_BASE_URL || "".
- script.js calls GET /api/health.
- script.js calls GET /api/feed/digest/latest?edition=breaking.
- renderHealthUnavailable fallback remains present.
- renderDigestUnavailable fallback remains present.
- raw JSON dump is not introduced.
```

### Styling / design preservation

```text
Result: PASS_SOURCE
Evidence:
- apps/web/styles.css was not changed by PR #316.
- Existing HTML/CSS/JS shell and styling were preserved.
- No frontend framework bundle was introduced.
```

### Forbidden surfaces

```text
Result: PASS_SOURCE
Evidence:
- No poll UI added.
- No audit UI added.
- No public Source Health UI added.
- No login UI added.
- No identity provider callback route added.
- No backend route or JSON response-shape change added by the Pages source update.
```

## GitHub Actions Status Observed

After PR #316 merge, GitHub Actions for the merge commit showed:

```text
Phase 0 validate: completed, success
Phase 0 report: completed, success
Phase 1 backend verify: completed, failure
Phase 1 runtime smoke/report/diagnose/trace: in_progress or queued during observation
```

The Phase 1 backend verify failure was not introduced by this Pages-only source update scope and is outside this Pages smoke record unless later investigation ties it to these two static frontend files.

The GitHub connector did not expose a dedicated `Deploy Phase 0 web to GitHub Pages` run in the observed commit workflow list. The workflow file is present on `phase0-foundation`; if the Pages deployment does not appear in the GitHub UI, manually dispatch `.github/workflows/deploy-pages-phase0.yml` from `phase0-foundation`.

## External URL Smoke Attempt

Target URLs:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
https://suam4597-ship-it.github.io/disclosure-automation/index.html
https://suam4597-ship-it.github.io/disclosure-automation/script.js
https://suam4597-ship-it.github.io/disclosure-automation/styles.css
```

Observed from this execution environment:

```text
Result: INCONCLUSIVE_FROM_EXECUTOR_ENVIRONMENT
web fetch: no usable page body returned
container curl: DNS resolution failed for suam4597-ship-it.github.io
```

Because the execution environment could not fetch the external Pages host, this document does not claim browser/HTTP external smoke pass.

## Current Conclusion

```text
LOCAL_SMOKE_PASS
LOCAL_STAGING_LIKE_SMOKE_PASS
AUTOMATED_CONTRACT_SMOKE_PASS
GITHUB_PAGES_SOURCE_UPDATED
GITHUB_PAGES_SOURCE_CONTRACT_PASS
GITHUB_PAGES_EXTERNAL_URL_SMOKE_INCONCLUSIVE_FROM_EXECUTOR_ENVIRONMENT
BROWSER_VISUAL_SMOKE_NOT_RUN_NODE_REPL_VERSION
```

The Fast MVP shell is now present in the GitHub Pages source branch. External Pages URL smoke remains inconclusive from this executor environment until the Pages host can be fetched successfully.

## Recommended Next Action

From a machine/browser that can resolve GitHub Pages, run:

```text
GET https://suam4597-ship-it.github.io/disclosure-automation/
GET https://suam4597-ship-it.github.io/disclosure-automation/index.html
GET https://suam4597-ship-it.github.io/disclosure-automation/script.js
GET https://suam4597-ship-it.github.io/disclosure-automation/styles.css
```

Expected checks:

```text
/ or /index.html returns latest shell
latest-digest-card present
backend-status-card present
operator-source-health-link present
script.js references /api/health
script.js references /api/feed/digest/latest?edition=breaking
backend unavailable fallback renders safely if no same-origin backend exists
no poll UI, audit UI, public Source Health UI, login UI, or frontend framework bundle appears
```

If GitHub Actions UI does not show the Pages deploy run for merge commit `c48583f38204c408f744fe8a888e97bbe6c23b3e`, manually dispatch:

```text
workflow: Deploy Phase 0 web to GitHub Pages
branch: phase0-foundation
```

## Rollback Plan

If the shared Pages surface needs to be rolled back:

```text
revert PR #316 merge commit c48583f38204c408f744fe8a888e97bbe6c23b3e on phase0-foundation
confirm apps/web/index.html and apps/web/script.js return to the previous Phase 0 shell
allow the Pages workflow to redeploy or manually dispatch it from phase0-foundation
rerun the static URL checks
```

## Stop Conditions

Stop and re-scope if closing external Pages smoke requires:

```text
changing the existing HTML/CSS shell design
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
