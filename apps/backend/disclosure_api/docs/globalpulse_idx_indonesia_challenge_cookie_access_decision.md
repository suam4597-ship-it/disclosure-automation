# GlobalPulse IDX Indonesia Challenge Cookie Access Decision

Date: 2026-05-11 KST

This document records the access decision for the IDX Indonesia announcement JSON path after the Fly/Elixir runtime probe.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Decision

```text
IDX_CHALLENGE_COOKIE_ACCESS_DECISION_RECORDED
IDX_COOKIE_MEDIATED_API_200_IS_DIAGNOSTIC_ONLY
IDX_COOKIE_MEDIATED_API_200_IS_NOT_SOURCE_REGISTRATION_APPROVAL
IDX_SOURCE_REGISTRATION_REMAINS_BLOCKED
IDX_PARSER_SOURCE_CANDIDATE_NOT_ALLOWED_YET
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Inputs

```text
access path review: globalpulse_idx_indonesia_announcements_access_path_review.md
runtime probe: globalpulse_idx_indonesia_fly_elixir_runtime_probe_results.md
official page: https://www.idx.co.id/en/news/announcement/
official JSON endpoint: /primary/NewsAnnouncement/GetAllAnnouncement
bounded query shape: dateFrom/dateTo in YYYYMMDD, pageNumber=1, pageSize=10, lang=en
```

Observed Fly/Elixir runtime probe:

```text
direct API: 403 Cloudflare HTML
official page bootstrap: 403 Cloudflare HTML
page response cookie count: 1
API retry with page cookie: 200 application/json
ItemCount: 75
Items returned: 10
```

## Decision Rationale

The cookie-mediated API success proves that the official JSON shape can be reached from Fly under a specific request sequence. It does not prove that GlobalPulse has a clean, durable, policy-acceptable backend source path.

Reasons:

```text
The direct API request did not return JSON.
The official page bootstrap did not return normal page HTML.
Both returned Cloudflare 403 HTML.
The only successful JSON request depended on a cookie emitted by a challenge response.
The initial GlobalPulse candidate must avoid relying on challenge or anti-automation response artifacts.
```

## Operational Decision

```text
Do not add id_idx_announcements to source_registry.
Do not add idx_indonesia_announcements_json_v1 parser/source candidate.
Do not add an IDX staging poll workflow.
Do not run IDX live polling.
Do not fetch IDX attachment PDFs or detail documents.
Do not treat challenge-cookie-mediated success as live-source readiness.
```

IDX may be revisited only if one of these becomes true:

```text
1. A clean backend runtime path returns 2xx JSON without challenge HTML or challenge-cookie dependency.
2. IDX documents an approved API/data access route suitable for backend polling.
3. Product explicitly accepts a different authorized access path with rate/cadence and reuse terms recorded.
```

## Guardrails

```text
Do not add IDX as an rss_v1 source.
Do not use the HTML announcement page as source input.
Do not parse Nuxt inline state as the source.
Do not use third-party IDX mirrors or aggregators by default.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not claim fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Next Step

With SET holding the first ASEAN manual-staging lane and IDX blocked, the next safe options are:

```text
1. Repeat SET Thailand manual staging smoke in another observation window.
2. Continue APAC official-source scanning within official exchange/OAM surfaces.
3. Revisit ASX only after written authority or approved ASX Information Services path exists.
```
