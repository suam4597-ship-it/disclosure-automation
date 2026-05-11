# GlobalPulse APAC Next Live Source Decision

Date: 2026-05-11 KST

This document records the next-source decision after the first APAC/ASEAN/ANZ live endpoint expansion pass.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Decision

```text
APAC_NEXT_LIVE_SOURCE_DECISION_RECORDED
ASX_IS_STRONGEST_NEXT_TECHNICAL_ADAPTER_CANDIDATE
ASX_ADAPTER_BLOCKED_UNTIL_ACCESS_POLICY_DECISION
SET_IS_FIRST_ASEAN_RUNTIME_PROBE_CANDIDATE
IDX_IS_SECOND_ASEAN_RUNTIME_PROBE_CANDIDATE
KR_LIVE_SOURCE_TRACK_DEFERRED_UNTIL_DEDICATED_BACKEND_EXISTS
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Inputs Reviewed

```text
India NSE official RSS: staging-live verified and conservative staging schedule configured
SGX: official browser JSON path confirmed, blocked by policy/runtime review
Bursa Malaysia: official browser JSON path confirmed, blocked by Cloudflare/runtime fetch
SET Thailand: official JSON path confirmed, blocked pending bounded adapter and Fly/Elixir runtime probe
IDX Indonesia: official JSON path confirmed, blocked pending bounded adapter, query-shape policy, and Fly/Elixir runtime probe
ASX: official MarkitDigital JSON path confirmed, direct Node/PowerShell fetch passed, blocked pending access-policy decision
NZX: official contingency HTML surface confirmed, no machine-readable endpoint accepted
KR: explicitly deferred by product direction because the dedicated backend is not ready
JP: remains blocked by source-authority issue #339
```

## Recommended Order

```text
1. ASX access-policy decision
2. If ASX policy is accepted: bounded inactive ASX JSON parser/source candidate
3. If ASX policy is not accepted or delayed: SET Fly/Elixir runtime compatibility probe
4. If SET runtime probe passes: bounded inactive SET JSON parser/source candidate
5. If SET is blocked: IDX Fly/Elixir runtime compatibility probe using YYYYMMDD date-window query
6. Revisit SGX only after policy/permission and runtime compatibility are explicitly accepted
7. Revisit Bursa only if a non-bypass backend runtime fetch path is accepted
8. Keep KR last until its dedicated backend/source authority path exists
```

## Rationale

ASX is the strongest next technical candidate because:

```text
official ASX announcement surface confirmed
official ASX/MarkitDigital JSON endpoint observed
bounded page-0 query returned 200 application/json from PowerShell
bounded page-0 query returned 200 application/json from Node fetch
response shape is typed JSON and does not require parsing HTML table fragments
```

ASX is still blocked from source registration because:

```text
ASX market-announcement access is subject to ASX terms of use
market-data copyright restrictions are disclosed on the ASX announcement surface
GlobalPulse has not recorded an explicit access-policy decision for backend polling
no bounded ASX parser/source candidate exists yet
no Fly staging live-poll smoke exists yet
```

SET is the first ASEAN implementation fallback because:

```text
official SET company-news JSON path was observed
the response shape is typed JSON
local PowerShell could fetch JSON after normal page bootstrap and documented SET browser headers
```

SET remains behind ASX because:

```text
the API is not a simple standalone endpoint
fresh direct API probes returned Incapsula challenge HTML
Fly/Elixir bootstrap compatibility is not proven
```

IDX is behind SET because:

```text
official IDX JSON path was observed
bounded YYYYMMDD date-window query returned 200 JSON through Chromium network
direct Node and PowerShell probes returned Cloudflare/403
unbounded query shapes returned Varnish 503 HTML
```

## Guardrails

```text
Do not enable production APAC scheduled polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not fetch ASX, IDX, SET, SGX, Bursa, or NZX document/PDF attachments in initial candidates.
Do not treat browser-only success as backend live-source readiness.
Do not treat fixture fallback as live success.
Do not use third-party aggregators by default.
Do not start KR live polling until the dedicated KR backend/source path exists.
Do not start JP live polling until issue #339 is resolved.
```

## Next PR Candidates

```text
1. Record ASX MarkitDigital announcements access-policy decision
2. Add bounded inactive ASX market-announcements parser/source candidate
3. Add ASX manual staging live poll smoke
4. Add SET Fly/Elixir runtime compatibility probe
5. Add IDX Fly/Elixir runtime compatibility probe
```
