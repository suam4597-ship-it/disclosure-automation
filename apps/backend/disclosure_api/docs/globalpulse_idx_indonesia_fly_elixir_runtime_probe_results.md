# GlobalPulse IDX Indonesia Fly Elixir Runtime Probe Results

Date: 2026-05-11 KST

This document records the Fly staging runtime probe for the official Indonesia Stock Exchange announcement JSON access path.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
IDX_INDONESIA_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
IDX_INDONESIA_DIRECT_API_FETCH_BLOCKED_BY_CLOUDFLARE_403
IDX_INDONESIA_PAGE_BOOTSTRAP_BLOCKED_BY_CLOUDFLARE_403
IDX_INDONESIA_COOKIE_MEDIATED_API_FETCH_RETURNS_JSON_200
IDX_INDONESIA_SOURCE_REGISTRATION_STILL_BLOCKED_BY_CHALLENGE_COOKIE_DEPENDENCY
IDX_CHALLENGE_COOKIE_ACCESS_DECISION_RECORDED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Environment

```text
Fly app: globalpulse-backend-staging
staging host: https://globalpulse-backend-staging.fly.dev
deployed image observed before probe: registry.fly.io/globalpulse-backend-staging:deployment-01KRAJMWDZGXQ1842RV278MNBP
runtime path: /app/bin/disclosure_automation eval
HTTP path: Erlang :httpc through DisclosureAutomation.Http.fetch/2
```

The probe started `:ssl` and `:inets` inside the release eval session before calling `DisclosureAutomation.Http.fetch/2`. Fly CLI on Windows returned `The handle is invalid` after the remote eval printed the probe output. The remote output was emitted, so this is treated as a local Fly CLI teardown warning rather than an IDX HTTP result.

## Probe Target

```text
official page:
https://www.idx.co.id/en/news/announcement/

official JSON endpoint:
https://www.idx.co.id/primary/NewsAnnouncement/GetAllAnnouncement?dateFrom=20260511&dateTo=20260511&pageNumber=1&pageSize=10&lang=en

dateFrom: 20260511
dateTo: 20260511
pageNumber: 1
pageSize: 10
lang: en
```

Headers used in the direct API probe were bounded and non-secret:

```text
user-agent: Mozilla/5.0 GlobalPulse IDX runtime probe
accept: application/json, text/plain, */*
accept-language: en-US,en;q=0.9
referer: https://www.idx.co.id/en/news/announcement/
```

No raw cookies, raw response body, detail pages, attachments, or issuer files were recorded.

## Direct API Probe

Observed result:

```text
status: 403
content_type: text/html; charset=UTF-8
bytes: 5904
json: false
cloudflare_marker: true
varnish_marker: false
html_marker: true
item_count: nil
items: nil
```

Interpretation:

```text
Fly staging cannot treat the direct IDX JSON endpoint as backend-live-source-ready.
The direct API path returned Cloudflare HTML, not JSON.
This is not acceptable as source-registration evidence.
```

## Page Bootstrap Probe

Observed result:

```text
status: 403
content_type: text/html; charset=UTF-8
bytes: 5466
json: false
cloudflare_marker: true
varnish_marker: false
html_marker: true
page_cookie_count: 1
```

Interpretation:

```text
The official announcement page did not return a normal rendered HTML page through the Fly Elixir runtime.
It returned Cloudflare HTML and one cookie.
This is not a clean page-bootstrap pass.
```

## Cookie-Mediated API Probe

The probe then retried the same bounded JSON endpoint using the cookie emitted by the 403 page response.

Observed result:

```text
status: 200
content_type: application/json; charset=utf-8
bytes: 21590
json: true
item_count: 75
items: 10
cloudflare_marker: false
varnish_marker: false
html_marker: false
```

Interpretation:

```text
The official IDX JSON shape is reachable from Fly only after a challenge-cookie-mediated request sequence in this probe.
That is useful diagnostic evidence but not yet acceptable source-registration evidence.
GlobalPulse should not add an IDX source until a clean, policy-acceptable backend runtime path is accepted.
```

## Source Registration Decision

Do not register an IDX Indonesia source yet.

Current decision:

```text
source key proposal: id_idx_announcements
parser/adapter proposal: idx_indonesia_announcements_json_v1
registration status: blocked
blocking class: challenge_cookie_dependency + bounded_adapter_required + query_shape_policy
access decision: globalpulse_idx_indonesia_challenge_cookie_access_decision.md
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## Guardrails

```text
Do not add IDX as an rss_v1 source.
Do not treat the HTML page or Nuxt inline state as live source input.
Do not treat Cloudflare challenge HTML as live-source success.
Do not treat challenge-cookie-mediated API success as automatic source-registration approval.
Do not fetch issuer attachment PDFs in the initial candidate.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party IDX mirrors or aggregators by default.
Do not treat fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Repeat SET Thailand manual staging live smoke in another observation window.
2. Continue APAC official-source scanning only within official exchange/OAM surfaces.
3. Revisit IDX only if a clean backend runtime or approved data-access path is documented.
```
