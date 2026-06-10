# GlobalPulse Fly Staging Smoke Results

This document records the stable Fly.io staging backend smoke result for the GlobalPulse GitHub Pages frontend.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
frontend deployment: GitHub Pages
frontend source branch: phase0-foundation
GlobalPulse root PR: #325 Promote GlobalPulse dashboard to Pages root
Fly staging config PR: #327 Add GlobalPulse Fly staging backend config
Fly default config PR: #328 Connect GlobalPulse Pages to Fly staging backend
Fly default config merge commit: 48db185fe96e952b896cc3bc97ed466707c7e792
smoke type: stable Fly.io staging backend + GitHub Pages browser smoke
smoke result source: user-provided browser/Fly validation plus GitHub connector CI/repo verification
executor environment note: ChatGPT execution environment could not fetch the GitHub Pages or Fly public URLs directly, so external HTTP/browser claims in this record rely on user-provided smoke output.
```

## Stable Staging Backend

```text
Backend URL: https://globalpulse-backend-staging.fly.dev/
Fly backend app: globalpulse-backend-staging
Fly Postgres app: globalpulse-db-staging
```

Fly Postgres status reported by the executor:

```text
started
primary
checks: 3/3 passing
5-minute trial stop limitation: resolved after billing was enabled
availability observation: stayed running beyond 5 minutes
```

Backend deployment status reported by the executor:

```text
deploy: PASS
release migration: PASS
```

## Backend API Smoke

### Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
Result: PASS
HTTP status: 200
Response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

### Fixture-backed source poll

```text
POST /api/admin/sources/sec_press_releases/poll with fixture-backed data
Result: PASS
HTTP status: 202
records_inserted: 2
```

### Latest digest

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
Result: PASS
HTTP status: 200
edition: breaking
item_count: 2
```

### CORS

```text
CORS for GitHub Pages origin: PASS
Expected allowed origin: https://suam4597-ship-it.github.io
```

## Frontend Default Backend Configuration

PR #328 changed `apps/web/config.js` so the public GitHub Pages frontend uses the Fly staging backend by default:

```text
window.DISCLOSURE_API_BASE_URL =
  window.DISCLOSURE_API_BASE_URL || "https://globalpulse-backend-staging.fly.dev";
```

This means the default public frontend URL should now connect to Fly staging without a query parameter:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

One-off override remains available for smoke tests:

```text
https://suam4597-ship-it.github.io/disclosure-automation/?apiBase=<backend-url>
```

## CI Status After Fly Default Config

GitHub connector verification for PR #328 merge commit:

```text
commit: 48db185fe96e952b896cc3bc97ed466707c7e792
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Expected Browser Smoke Result

After GitHub Pages redeploys commit `48db185fe96e952b896cc3bc97ed466707c7e792`, opening the default public URL should show:

```text
GlobalPulse dashboard shell: PASS
backend status badge: connected/ok
GET /api/health through configured Fly base URL: PASS
GET /api/feed/digest/latest?edition=breaking through configured Fly base URL: PASS
digest items rendered from Fly staging backend: PASS, expected item_count=2
fatal browser console errors: none expected
```

## Current Conclusion

```text
GLOBALPULSE_PAGES_ROOT_PASS
FLY_STAGING_BACKEND_DEPLOY_PASS
FLY_POSTGRES_STAGING_PASS
RELEASE_MIGRATION_PASS
CORS_GITHUB_PAGES_PASS
BACKEND_HEALTH_PASS
FIXTURE_POLL_PASS
DIGEST_API_PASS
GLOBALPULSE_PAGES_CONFIGURED_TO_FLY_STAGING_BY_DEFAULT
GLOBALPULSE_PAGES_TO_FLY_STAGING_SMOKE_READY
```

`GLOBALPULSE_PAGES_TO_FLY_STAGING_BROWSER_SMOKE_PASS` should be marked after a browser confirms that the redeployed GitHub Pages frontend loaded the updated `config.js` and rendered backend digest data from Fly staging.

## Recommended Next Action

Run browser smoke against:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Expected checks:

```text
/config.js contains https://globalpulse-backend-staging.fly.dev
Network: GET https://globalpulse-backend-staging.fly.dev/api/health -> 200
Network: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking -> 200
UI: backend status badge shows connected/ok
UI: first feed region updates from backend digest data
UI: 2 backend digest items are visible
Console: no fatal CORS or JavaScript errors
```

If the old static demo mode still appears, hard-refresh or wait for GitHub Pages/CDN cache to update, then verify that `/config.js` returns the `globalpulse-backend-staging.fly.dev` value.

## Remaining Production/Staging Hardening

This is a stable staging smoke, not production readiness. Remaining work before production-like use:

```text
monitoring/alerting for Fly app and Postgres
backup/restore policy for staging database
cost and auto-stop policy review
secrets rotation process
origin allowlist review
live source polling policy
fixture vs live data switch documentation
runtime deployment rollback playbook
```

## Stop Conditions

Stop and re-scope if closing production readiness requires:

```text
adding a frontend framework
changing backend JSON response shapes without focused contract tests
adding login UI
adding identity provider callback routes
adding poll UI
adding audit UI
adding public Source Health UI
trusting request-param actor_permissions as production authority
returning raw provider/auth/session/request material
using a temporary localtunnel URL as stable staging
```
