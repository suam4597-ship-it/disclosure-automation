# GlobalPulse IDX Indonesia Announcements Access Path Review

Date: 2026-05-11 KST

This document records a focused follow-up review of the Indonesia Stock Exchange announcement access path after SGX, Bursa Malaysia, and SET Thailand were reviewed for ASEAN listed-company disclosure coverage.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
IDX_INDONESIA_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
IDX_INDONESIA_ANNOUNCEMENTS_JSON_SHAPE_CAPTURED_BOUNDED
IDX_INDONESIA_DIRECT_NODE_AND_POWERSHELL_FETCH_BLOCKED_BY_CLOUDFLARE
IDX_INDONESIA_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
IDX_INDONESIA_SOURCE_REGISTRATION_STILL_BLOCKED_BY_CHALLENGE_COOKIE_DEPENDENCY
ASEAN_SOURCE_REGISTRATION_STILL_BLOCKED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Surface

```text
official page: https://www.idx.co.id/en/news/announcement/
alternate official page: https://www.idx.id/en/news/announcement/
page title: Announcements
category: Indonesia / ASEAN listed-company announcements
rendered date observed: 11 May 2026
```

The browser-rendered page displayed official IDX announcements and a disclaimer that only three years of data are available on the website, with older historical data available through TICMI.

Observed first rendered announcements included:

```text
REPORT OF OWNERSHIP OR ANY CHANGES IN SHARE OWNERSHIP OF PUBLIC COMPANIES [BULL]
Announcement of Planning of Annual and Extraordinary General Meeting of Shareholders [TBLA]
Monthly Report of Securities Holders Registration (CORRECTION) [KEEN]
Monthly Report of Securities Holders Registration (CORRECTION) [ASRM]
```

## Browser Access Path

The public page is a Nuxt app. The announcement component uses an official IDX JSON endpoint:

```text
GET https://www.idx.co.id/primary/NewsAnnouncement/GetAllAnnouncement
query params observed:
  keywords
  pageNumber
  pageSize
  dateFrom
  dateTo
  lang
```

Client-side search request observed:

```text
GET https://www.idx.co.id/primary/NewsAnnouncement/GetAllAnnouncement?keywords=BULL&pageNumber=1&pageSize=10&lang=en
headers observed:
  Accept: application/json, text/plain, */*
  Accept-Language: en-US
  Referer: https://www.idx.co.id/en/news/announcement/
```

The browser response returned HTTP 200 JSON:

```text
top-level keys: Items, ItemCount, PageSize, PageNumber, PageCount
ItemCount for keyword BULL observed: 233
items returned on page 1: 10
```

Observed first keyword-filtered item shape:

```text
Id: 20260511094728-LK/11052026/0002/1_en-us
AnnouncementNo: LK/11052026/0002/1
PublishDate: 2026-05-11T09:47:28
Title: REPORT OF OWNERSHIP OR ANY CHANGES IN SHARE OWNERSHIP OF PUBLIC COMPANIES
AnnouncementType: LKS
Code: BULL
Jenis: STOCK
Attachments: bounded attachment metadata with official IDX static-data URLs
```

Date-window request behavior:

```text
dateFrom/dateTo format YYYYMMDD returned 200 JSON.
Example: dateFrom=20260511&dateTo=20260511 returned ItemCount=37 and 10 page-1 items.
ISO-style dates and slash/dash local date formats returned 503 Varnish HTML in this probe.
```

Do not fetch attachments in an initial candidate. The safe parser boundary, if approved later, should stay on list metadata and attachment metadata only.

## Runtime Fetch Notes

Observed request behavior:

```text
browser-rendered page at www.idx.co.id: 200
browser-rendered page at www.idx.id: 200
old /en-us/ announcement path: 503 after redirect
browser client-side request to /primary/NewsAnnouncement/GetAllAnnouncement: 200 application/json
fresh Playwright Chromium API request with browser-like headers: 200 application/json for accepted query shapes
direct Node fetch with the same browser-like headers: 403 Cloudflare challenge HTML
direct PowerShell request with browser-like headers: 403
unbounded empty query shape returned 503 Varnish HTML in this probe
```

Implication:

```text
The official IDX announcement JSON shape is proven for bounded query shapes.
The endpoint is not yet proven from the backend runtime stack that GlobalPulse uses.
The accepted path may depend on Chromium-like network behavior or other edge controls.
The Fly/Elixir runtime probe is now recorded in globalpulse_idx_indonesia_fly_elixir_runtime_probe_results.md.
Direct API and page-bootstrap fetches returned Cloudflare 403 HTML from Fly staging.
A cookie-mediated retry returned 200 JSON, but that challenge-cookie dependency is not clean source-registration evidence.
Do not register IDX Indonesia as a live source until a policy-acceptable backend runtime path is accepted.
```

## Source Registration Decision

Do not register an IDX Indonesia source yet.

Current decision:

```text
source key proposal: id_idx_announcements
parser/adapter proposal: idx_indonesia_announcements_json_v1
registration status: blocked
blocking class: challenge_cookie_dependency + bounded_adapter_required + query_shape_policy
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## If Runtime Access Is Accepted Later

If IDX runtime access becomes acceptable later, the first implementation should be bounded:

```text
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
endpoint: /primary/NewsAnnouncement/GetAllAnnouncement
pageNumber: 1
pageSize: 10 or lower
dateFrom/dateTo: YYYYMMDD bounded window
lang: en
detail/attachment fetch: disabled
stored fields: bounded list metadata and attachment metadata only
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

Required validation before any parser/source PR:

```text
Fly/Elixir runtime path returns 2xx JSON without Cloudflare challenge HTML or challenge-cookie dependency
parser rejects challenge pages, Varnish 503 pages, and non-JSON responses
parser extracts only bounded Items metadata
attachments are recorded as metadata only and not fetched
date-window query shape is documented
rate/cadence cap is documented
```

## Guardrails

```text
Do not add IDX as an rss_v1 source.
Do not treat the HTML page or Nuxt inline state as live source input.
Do not treat Cloudflare challenge or Varnish 503 HTML as live-source success.
Do not fetch issuer attachment PDFs in the initial candidate.
Do not enable ASEAN scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party IDX mirrors or aggregators by default.
```

## Allowed Next PRs

```text
1. Record an IDX access decision that challenge-cookie-mediated backend fetch is not enough for source registration.
2. Add a bounded inactive IDX JSON parser/source candidate only if runtime fetch and access gates pass later.
3. Repeat SET Thailand manual staging smoke in another observation window.
4. Continue APAC official-source scanning within official exchange/OAM surfaces.
```
