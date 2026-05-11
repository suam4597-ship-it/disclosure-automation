# GlobalPulse SET Thailand Fly Elixir Runtime Probe Results

Date: 2026-05-11 KST

This document records the Fly staging runtime probe for the official Stock Exchange of Thailand company-news JSON access path.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
SET_THAILAND_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
SET_THAILAND_FLY_ELIXIR_HTTP_WRAPPER_FETCH_PASS
SET_THAILAND_BOOTSTRAP_PLUS_API_PROBE_PASS
SET_THAILAND_API_RETURNS_JSON_FROM_FLY_STAGING
SET_THAILAND_CHALLENGE_HTML_NOT_OBSERVED_FROM_FLY_STAGING
SET_THAILAND_BOUNDED_INACTIVE_SOURCE_CANDIDATE_ADDED
SET_THAILAND_MANUAL_STAGING_SMOKE_PASS
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Environment

```text
Fly app: globalpulse-backend-staging
Fly machine: 9080d12db6d338
Fly region: nrt
staging host: https://globalpulse-backend-staging.fly.dev
deployed image observed before probe: registry.fly.io/globalpulse-backend-staging:deployment-01KR99PYFEPADYCJF6DZTQW7TV
runtime path: /app/bin/disclosure_automation eval
HTTP path: Erlang :httpc through DisclosureAutomation.Http.fetch/2
```

The machine was stopped before the probe. It was started for the runtime check and stopped again after the probe. That was an operational check only; no repository, image, runtime, or deployment change was made.

Fly CLI on Windows returned `The handle is invalid` after the remote eval printed the probe output. The probe output was still emitted by the remote release command, so this is treated as a local Fly CLI teardown warning rather than a SET HTTP failure.

## Probe Target

```text
official page:
https://www.set.or.th/en/market/news-and-alert/news?newsType=company

official JSON endpoint:
https://www.set.or.th/api/cms/v1/news/set?sourceId=company&securityTypeIds=S&fromDate=11/05/2026&toDate=11/05/2026&orderBy=date&lang=en

sourceId: company
securityTypeIds: S
fromDate: 11/05/2026
toDate: 11/05/2026
orderBy: date
lang: en
```

Headers used in the direct HTTP-wrapper probe were bounded and non-secret:

```text
user-agent: Mozilla/5.0 GlobalPulse SET runtime probe
accept: application/json, text/plain, */*
accept-language: en-US,en;q=0.9
referer: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
x-channel: WEB_SET
x-client-uuid: fixed non-secret probe UUID
```

No raw cookies, raw response body, detail pages, or attachments were recorded.

## Direct HTTP Wrapper Probe

This probe used the current release helper path:

```text
DisclosureAutomation.Http.fetch/2
```

Observed result:

```text
http_wrapper: true
api_status: 200
api_content_type: application/json; charset=utf-8
api_bytes: 25396
api_json: true
news_group_count: 2
total_count: 63
```

Interpretation:

```text
Fly staging can fetch the official SET JSON endpoint using the same Erlang :httpc wrapper used by application live fetches.
The endpoint returned JSON, not challenge HTML.
The bounded response shape still exposes newsGroups with two groups and a non-empty total count.
```

## Bootstrap Plus API Probe

The bootstrap probe first loaded the official company-news page, captured only the count of session cookies, then called the API with the bounded browser-style headers and cookie header.

Observed result:

```text
page_status: 200
page_content_type: text/html; charset=utf-8
page_bytes: 428458
page_cookie_count: 4
api_status: 200
api_content_type: application/json; charset=utf-8
api_bytes: 25388
api_json: true
news_groups_present: true
news_group_count: 2
total_count: 63
challenge_html_marker: false
incapsula_marker: false
```

Interpretation:

```text
The page bootstrap path also works from Fly staging.
The API response did not contain the bounded challenge markers checked by the probe.
The current evidence no longer requires claiming browser-only success for SET Thailand.
```

## Source Registration Decision

This probe does not register a source.

Current SET decision:

```text
source key proposal: th_set_company_news
parser/adapter proposal: set_thailand_company_news_json_v1
runtime fetch status: passed
registration status: inactive manual-staging-only candidate
blocking class: repeated_observation_window_required
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## Current Implementation Step

The bounded inactive SET JSON adapter/source candidate has been added under:

```text
source: th_set_company_news
parser: set_thailand_company_news_json_v1
fixture: source_payloads/th_set_company_news.json
notes: globalpulse_set_thailand_company_news_candidate_notes.md
manual smoke: globalpulse_set_thailand_manual_staging_poll_smoke_results.md
```

Before any source activation or schedule, the candidate still needs:

```text
manual poll command documented
manual Fly staging smoke passed
fixture_fallback=false confirmed from live poll metadata
digest impact recorded
repeated manual staging smoke in another observation window
rollback path documented
```

## Guardrails

```text
Do not add SET as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not fetch detail pages or issuer attachments in the initial candidate.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party SET mirrors or aggregators by default.
Do not treat fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Repeat SET manual Fly staging live poll smoke in another observation window.
2. If repeated SET staging smoke fails, record the bounded failure and fix the smallest parser/live-fetch issue.
3. If SET repeated smoke is delayed, continue to IDX Fly/Elixir runtime compatibility probe.
```
