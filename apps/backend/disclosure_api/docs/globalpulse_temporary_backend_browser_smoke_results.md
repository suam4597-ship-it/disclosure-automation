# GlobalPulse Temporary Backend Browser Smoke Results

This document records a temporary browser smoke result for the GlobalPulse GitHub Pages frontend connected to an external temporary backend tunnel.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
frontend deployment: GitHub Pages
frontend source branch: phase0-foundation
frontend root update PR: #325 Promote GlobalPulse dashboard to Pages root
frontend root merge commit: d3fb1142b9cc88770e5a918624a1815e48c084bd
smoke type: browser smoke with temporary external backend URL
smoke result source: user-provided browser/local tunnel verification
executor environment note: ChatGPT execution environment could not resolve the localtunnel or GitHub Pages hosts, so this record relies on the user's browser/tunnel verification output
```

## Temporary Backend Configuration

Backend API base URL used for browser smoke:

```text
https://cuddly-stars-feel.loca.lt
```

GitHub Pages browser smoke URL:

```text
https://suam4597-ship-it.github.io/disclosure-automation/?apiBase=https%3A%2F%2Fcuddly-stars-feel.loca.lt
```

Topology:

```text
GitHub Pages frontend
  -> ?apiBase=https://cuddly-stars-feel.loca.lt
  -> temporary CORS proxy
  -> local Phoenix backend on 127.0.0.1:4000
  -> local Postgres fixture-backed data
```

Important limitation:

```text
This is a temporary smoke-only backend URL.
It is available only while the local Phoenix server and localtunnel/CORS proxy process are running.
It is not a stable staging or production backend URL.
```

A direct backend tunnel was also created:

```text
https://shiny-terms-repair.loca.lt
```

The direct backend tunnel was not selected for browser smoke because it did not provide the required CORS headers for GitHub Pages browser fetch.

## Backend Endpoint Smoke

### Health

```text
GET https://cuddly-stars-feel.loca.lt/api/health
Result: PASS
HTTP status: 200
Response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

### Latest digest

```text
GET https://cuddly-stars-feel.loca.lt/api/feed/digest/latest?edition=breaking
Result: PASS
HTTP status: 200
edition: breaking
item_count: 2
```

### CORS

```text
Access-Control-Allow-Origin: *
OPTIONS /api/health: 204
Result: PASS_FOR_BROWSER_SMOKE
```

## Browser Smoke Expected UI Result

When opening:

```text
https://suam4597-ship-it.github.io/disclosure-automation/?apiBase=https%3A%2F%2Fcuddly-stars-feel.loca.lt
```

Expected UI result:

```text
Static demo mode should be replaced by backend connected/ok status.
/api/health should succeed through the temporary CORS proxy.
Latest digest should load from the backend.
The first feed region should update with fixture-backed breaking digest items.
The rendered backend digest should show 2 items.
The GlobalPulse shell should remain usable if the temporary tunnel later expires.
```

## Current Conclusion

```text
GITHUB_PAGES_GLOBALPULSE_ROOT_DEPLOYED
PHASE0_VALIDATE_PASS
PHASE0_REPORT_PASS
PHASE1_BACKEND_VERIFY_PASS
PHASE1_RUNTIME_SMOKE_PASS
TEMPORARY_BACKEND_HEALTH_PASS
TEMPORARY_BACKEND_DIGEST_PASS
TEMPORARY_BACKEND_CORS_PASS
TEMPORARY_BACKEND_BROWSER_SMOKE_READY
STABLE_EXTERNAL_BACKEND_STAGING_NOT_CONFIGURED
```

This closes the temporary backend browser-smoke setup path, but it does not close stable external staging because the backend URL is temporary and depends on a local machine/tunnel process.

## Next Recommended Work

Recommended next PR when moving beyond temporary smoke:

```text
Configure stable GlobalPulse backend staging
```

Required inputs for stable staging:

```text
stable backend hosting target
stable backend URL
DATABASE_URL
SECRET_KEY_BASE
PHX_HOST
PORT
CORS allowed origin for https://suam4597-ship-it.github.io
runtime deployment credentials
Postgres persistence/backup decision
source polling policy for live vs fixture-backed data
```

Recommended browser smoke after stable staging exists:

```text
GET https://stable-backend.example.com/api/health -> 200
GET https://stable-backend.example.com/api/feed/digest/latest?edition=breaking -> 200
OPEN https://suam4597-ship-it.github.io/disclosure-automation/?apiBase=https%3A%2F%2Fstable-backend.example.com
VERIFY backend connected status
VERIFY digest items render from backend
VERIFY no fatal browser console errors
VERIFY fallback still works if backend is unavailable
```

## Stop Conditions

Stop and re-scope if closing stable backend smoke requires:

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
using a temporary localtunnel URL as a stable production/staging URL
```
