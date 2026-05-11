# GlobalPulse SET Thailand Company News Access Path Review

Date: 2026-05-11 KST

This document records a focused follow-up review of the Stock Exchange of Thailand company-news access path after SGX and Bursa Malaysia were reviewed for ASEAN listed-company disclosure coverage.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
SET_THAILAND_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
SET_THAILAND_COMPANY_NEWS_JSON_SHAPE_CAPTURED_BOUNDED
SET_THAILAND_DIRECT_API_FETCH_BLOCKED_WITHOUT_SESSION_BOOTSTRAP
SET_THAILAND_FLY_ELIXIR_RUNTIME_PROBE_PASS
SET_THAILAND_BOUNDED_INACTIVE_SOURCE_CANDIDATE_ADDED
SET_THAILAND_MANUAL_STAGING_SMOKE_PASS
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Surface

```text
official page: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
page title: News - The Stock Exchange of Thailand
category: Thailand / ASEAN listed-company news and announcements
rendered date observed: 11 May 2026
rendered groups observed: Financial Statement and News
```

The browser-rendered page displayed official company-news results with:

```text
Date/Time
Symbol
Source
Headlines
```

Observed listed issuers included BKA, TOP, DHOUSE, YGG, VCOM, MCS, HL, SUTHA, RPH, and TM.

## Browser Access Path

The public page uses a Nuxt frontend and calls an official SET CMS JSON endpoint:

```text
GET https://www.set.or.th/api/cms/v1/news/set?sourceId=company&securityTypeIds=S&fromDate=11/05/2026&toDate=11/05/2026&orderBy=date&lang=en
headers observed:
  Accept: application/json, text/plain, */*
  Accept-Language: en-US
  Referer: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
  X-Channel: WEB_SET
  X-Client-Uuid: generated browser UUID
```

The browser response returned HTTP 200 JSON:

```text
top-level keys: newsGroups, paginateNews
group: Financial Statement
financial-statement totalCount observed: 12
group: News
news totalCount observed: 51
```

Observed first item shape:

```text
id: 17784560467780
datetime: 2026-05-11T08:49:44+07:00
symbol: BKA
source: BKA
headline: Financial Statement Quarter 1/2026 (Reviewed)
url: https://www.set.or.th/en/market/news-and-alert/newsdetails?id=17784560467780&symbol=BKA
tag: financial-statement
product: S
```

The response is typed JSON and does not require parsing table-cell HTML fragments.

## Runtime Fetch Notes

Observed request behavior:

```text
browser-rendered page: 200
browser XHR to /api/cms/v1/news/set: 200 application/json
direct PowerShell page request: 200 text/html
fresh direct API request: 403 Incapsula challenge HTML
fresh Playwright API request: 403 Incapsula challenge HTML
PowerShell page bootstrap followed by API request with SET browser headers: 200 application/json
Playwright browser-context request after page load: 200 application/json
```

Implication:

```text
The official SET JSON shape is proven.
The API is not a simple standalone unauthenticated endpoint.
The accepted path appears to require a bounded session bootstrap from the official page plus documented SET browser headers.
The Fly/Elixir runtime probe is now recorded in globalpulse_set_thailand_fly_elixir_runtime_probe_results.md and returned 2xx JSON from Fly staging without challenge HTML.
```

SET is still not active-source-ready because it has one manual staging live-poll pass and still needs repeated observation-window evidence before activation or scheduling.

## Source Registration Decision

Do not activate the SET Thailand source yet.

Current decision:

```text
source key proposal: th_set_company_news
parser/adapter proposal: set_thailand_company_news_json_v1
registration status: inactive manual-staging-only candidate
blocking class: repeated_observation_window_required
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## Candidate Implementation

The first SET implementation is bounded:

```text
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
endpoint: /api/cms/v1/news/set
sourceId: company
securityTypeIds: S
date range: one day or another explicit bounded window
orderBy: date
lang: en
detail/attachment fetch: disabled
stored fields: bounded list metadata only
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

Required validation before any source activation:

```text
Fly/Elixir runtime bootstrap probe returns 2xx JSON without challenge HTML: complete
parser rejects challenge pages and non-JSON responses
parser extracts only bounded newsGroups/newsInfoList metadata
no detail pages or attachment documents are fetched
rate/cadence cap is documented
SET access/session behavior is recorded
manual Fly staging smoke passes with fixture_fallback=false
repeated manual Fly staging smoke passes in another observation window
```

## Guardrails

```text
Do not add SET as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not treat fresh API 403/Incapsula responses as live-source success.
Do not bypass Incapsula or other anti-automation controls.
Do not fetch detail pages or issuer attachments in the initial candidate.
Do not enable ASEAN scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party SET mirrors or aggregators by default.
```

## Allowed Next PRs

```text
1. Repeat SET manual Fly staging live poll smoke in another observation window.
2. If repeated SET staging smoke fails, record the bounded failure and fix the smallest parser/live-fetch issue.
3. If SET repeated smoke is delayed, continue to IDX Fly/Elixir runtime compatibility probe.
```
