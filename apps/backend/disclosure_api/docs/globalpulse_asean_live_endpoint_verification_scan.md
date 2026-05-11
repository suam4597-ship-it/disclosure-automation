# GlobalPulse ASEAN Live Endpoint Verification Scan

This document records the first ASEAN exact-endpoint verification pass after APAC fixture/UI coverage and the India NSE staging-live candidate work.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Status

```text
ASEAN_LIVE_SOURCE_SCAN_STARTED
ASEAN_OFFICIAL_SURFACES_FOUND
SGX_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
SGX_SOURCE_REGISTRATION_BLOCKED_BY_POLICY_REVIEW
BURSA_MALAYSIA_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
BURSA_MALAYSIA_SOURCE_REGISTRATION_BLOCKED_BY_CLOUDFLARE_RUNTIME_FETCH
SET_THAILAND_OFFICIAL_JSON_ACCESS_PATH_CONFIRMED
SET_THAILAND_FLY_ELIXIR_RUNTIME_PROBE_PASS
SET_THAILAND_BOUNDED_INACTIVE_SOURCE_CANDIDATE_ADDED
SET_THAILAND_MANUAL_STAGING_SMOKE_PASS
SET_THAILAND_REPEATED_MANUAL_STAGING_POLL_PASS
VIETNAM_HNX_ISSUER_DISCLOSURE_RSS_CONFIRMED
VIETNAM_HNX_ISSUER_DISCLOSURE_SOURCE_REGISTERED_INACTIVE
VIETNAM_HNX_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HNX_DIGEST_VISIBLE_LIVE
VIETNAM_HSX_LISTED_COMPANY_NEWS_RSS_CONFIRMED
VIETNAM_HSX_LISTED_COMPANY_NEWS_SOURCE_REGISTERED_INACTIVE
VIETNAM_HSX_MANUAL_STAGING_SMOKE_PENDING
IDX_INDONESIA_OFFICIAL_JSON_ACCESS_PATH_CONFIRMED
IDX_INDONESIA_FLY_ELIXIR_RUNTIME_PROBE_RECORDED
IDX_INDONESIA_SOURCE_REGISTRATION_STILL_BLOCKED_BY_CHALLENGE_COOKIE_DEPENDENCY
IDX_CHALLENGE_COOKIE_ACCESS_DECISION_RECORDED
ASEAN_MACHINE_READABLE_ENDPOINTS_CONFIRMED_BUT_NOT_ACCEPTED_FOR_SOURCE_REGISTRATION
ASEAN_ACTIVE_SOURCE_REGISTRATION_NOT_READY
ASEAN_SCHEDULED_LIVE_POLLING_BLOCKED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Baseline

```text
APAC fixture PR: #348 Add GlobalPulse APAC regional fixtures
APAC fixture smoke PR: #349 Record APAC regional public UI smoke
APAC live contract: globalpulse_apac_live_source_verification_contract.md
India NSE staging schedule activation PR: #366 Activate India NSE staging schedule on main
current branch: phase0-foundation
scan date: 2026-05-08 UTC / 2026-05-09 KST
SGX focused follow-up: globalpulse_sgx_company_announcements_access_path_review.md
Bursa Malaysia focused follow-up: globalpulse_bursa_malaysia_company_announcements_access_path_review.md
SET Thailand focused follow-up: globalpulse_set_thailand_company_news_access_path_review.md
IDX Indonesia focused follow-up: globalpulse_idx_indonesia_announcements_access_path_review.md
Vietnam HNX focused candidate: globalpulse_vietnam_hnx_issuer_rss_candidate_notes.md
Vietnam HSX focused candidate: globalpulse_vietnam_hsx_listed_company_news_candidate_notes.md
```

## Latest SGX Access-Path Addendum

```text
SGX company-announcements browser access path confirmed.
ANNOUNCEMENTS_API_URL observed as https://api.sgx.com/announcements/v1.1/.
Bounded first-page JSON response observed with 20 rows and links.sgx.com detail URLs.
The raw authorization token is not recorded.
Source registration remains blocked by SGX policy/permission review and backend runtime fetch compatibility.
```

## Latest Bursa Malaysia Access-Path Addendum

```text
Bursa Malaysia company-announcements browser access path confirmed.
XHR endpoint observed as https://www.bursamalaysia.com/api/v1/announcements/search?ann_type=company&per_page=20&page=1.
Bounded first-page JSON response observed with 20 table rows.
The JSON response contains table-cell HTML fragments rather than typed announcement objects.
Direct non-browser/API-context probes returned Cloudflare challenge or 403 responses.
Source registration remains blocked by runtime fetch compatibility.
```

## Latest SET Thailand Access-Path Addendum

```text
SET Thailand company-news browser access path confirmed.
Official JSON endpoint observed as /api/cms/v1/news/set with sourceId=company and securityTypeIds=S.
Bounded first-page JSON response observed with newsGroups/newsInfoList metadata.
Fresh direct API probes returned 403 Incapsula challenge HTML.
Normal page bootstrap plus SET browser headers returned 200 JSON in a local PowerShell session.
Fly/Elixir runtime probe from globalpulse-backend-staging returned 200 application/json through DisclosureAutomation.Http.fetch/2.
Bounded inactive source candidate added and repeated manual staging smoke passed.
Source activation and production scheduling remain blocked.
```

## Latest Vietnam HNX Access-Path Addendum

```text
Vietnam HNX issuer-disclosure RSS path confirmed.
Official RSS index listed the issuer-disclosure channel.
Bounded direct RSS request returned 200 application/rss+xml from www.hnx.vn.
Existing rss_v1 parser accepted the bounded fixture sample.
Bounded inactive source candidate added with disable_live_fixture_fallback=true.
Manual Fly staging smoke passed with fetch.mode=live and metadata.fallback_to_fixture=false.
Digest verification showed 6 HNX live items in the 12-item latest breaking digest.
Source activation and scheduling remain blocked.
```

## Latest Vietnam HSX Access-Path Addendum

```text
Vietnam HSX listed-company-news RSS path confirmed.
Official RSS index returned 200 application/rss+xml from api.hsx.vn.
Category feed 21 returned 200 application/rss+xml with channel title Tin To chuc niem yet.
Bounded direct RSS request observed 10 items with escaped HTML span titles and a10:updated timestamps.
rss_v1 parser behavior was aligned with the existing capability contract for HTML trimming and updated timestamp extraction.
Bounded inactive source candidate added with disable_live_fixture_fallback=true.
Manual Fly staging smoke is pending.
Source activation and scheduling remain blocked.
```

## Latest IDX Indonesia Access-Path Addendum

```text
IDX Indonesia announcement browser access path confirmed.
Official JSON endpoint observed as /primary/NewsAnnouncement/GetAllAnnouncement.
Bounded JSON response observed with Items, ItemCount, PageSize, PageNumber, and PageCount.
dateFrom/dateTo in YYYYMMDD format returned 200 JSON for a bounded date window.
Direct Node and PowerShell probes returned Cloudflare/403, while Playwright Chromium API returned 200 for accepted query shapes.
Fly/Elixir runtime probe recorded direct API/page-bootstrap Cloudflare 403 and cookie-mediated API 200 JSON.
IDX challenge-cookie access decision recorded; source registration remains blocked by challenge-cookie dependency, bounded adapter, and query-shape policy.
```

## Candidate Surfaces Checked

### SGX Company Announcements

```text
authority: official Singapore Exchange surface
candidate URL: https://www.sgx.com/securities/company-announcements
category: ASEAN listed-company announcements
quick result: 200 text/html
decision: official JSON access path observed, but source registration blocked by policy/runtime review
```

Observed:

```text
The public SGX company announcements page loads as HTML.
The page metadata describes latest company announcements, corporate actions, disclosures, and trading status.
The browser-rendered page displays a Date & Time / Issuer Name / Security Name / Title / Category table.
The frontend config exposes ANNOUNCEMENTS_API_URL=https://api.sgx.com/announcements/v1.1/.
The frontend retrieves a CMS validator and uses a derived authorizationToken header for the announcements API.
The raw authorization token is intentionally not recorded.
Browser-compatible requests returned HTTP 200 JSON from the v1.1 list API.
Direct unauthenticated API probes returned 403.
At least one non-browser PowerShell request with token returned Akamai Access Denied, so backend runtime fetch compatibility is still unproven.
```

Decision:

```text
Do not register SGX as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not treat the token-protected JSON path as accepted until SGX policy/permission, backend runtime fetch compatibility, parser shape, and rate limits are explicitly verified.
Do not store or log raw authorizationToken values.
SGX remains a strong ASEAN candidate, but it needs a policy-approved bounded JSON adapter path before source registration.
```

### Bursa Malaysia Company Announcements

```text
authority: official Bursa Malaysia announcement surface
candidate URL: https://www.bursamalaysia.com/market_information/announcements/company_announcement
disclaimer URL: https://www.bursamalaysia.com/disclaimer_company_announcement
category: ASEAN listed-company announcements
quick result: executor returned 403 for direct page/API probes
decision: official browser JSON endpoint observed, but source registration blocked by runtime fetch
```

Observed:

```text
Search-visible Bursa pages confirm official company-announcement surfaces and disclaimer language.
The browser-rendered page uses /api/v1/announcements/search with ann_type=company, per_page=20, and page=1.
The browser XHR returned HTTP 200 JSON with 20 table rows and recordsTotal/recordsFiltered metadata.
The response rows contain bounded HTML fragments for date, company profile link, and announcement detail link.
Direct non-browser/API-context probes returned 403 or Cloudflare challenge HTML.
No backend-runtime-compatible endpoint was accepted in this pass.
```

Decision:

```text
Do not register Bursa as an rss_v1 source.
Do not use third-party Bursa mirrors or listed-company investor-relations mirrors as GlobalPulse source authority without explicit acceptance.
Do not claim Bursa live source readiness from browser-only XHR success.
Do not bypass Cloudflare or other anti-automation controls.
Add a source only after a Fly/Elixir runtime fetch probe returns 2xx JSON without challenge HTML.
```

### SET Thailand Company News

```text
authority: official Stock Exchange of Thailand surface
candidate URL: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
category: ASEAN company news/announcements
quick result: page 200 text/html; browser/session JSON 200 application/json
decision: official JSON access path observed, but source registration blocked pending adapter/runtime probe
```

Observed:

```text
The official SET company news page returned HTML and rendered company-news results.
The page called /api/cms/v1/news/set with sourceId=company, securityTypeIds=S, a bounded date range, orderBy=date, and lang=en.
The browser XHR returned HTTP 200 JSON with newsGroups and newsInfoList metadata.
Fresh direct API probes returned 403 Incapsula challenge HTML.
A normal page bootstrap followed by the API request with X-Channel=WEB_SET and X-Client-Uuid returned 200 JSON in a local PowerShell session.
The Fly/Elixir runtime probe also returned 200 application/json through the application HTTP wrapper with two news groups and totalCount=63.
No bounded SET adapter/source candidate has been added yet.
```

Decision:

```text
Do not register SET as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not claim SET live readiness from browser-only success or fresh API 403 challenge responses.
Add a source only after a bounded JSON adapter, rate/cadence policy, and staging smoke pass.
```

### IDX Indonesia Announcements

```text
authority: official Indonesia Stock Exchange surface
candidate URL: https://www.idx.co.id/en/news/announcement/
alternate URL: https://www.idx.id/en/news/announcement/
category: ASEAN/Indonesia announcements
quick result: browser page 200; bounded Playwright Chromium API request 200 JSON; direct Node/PowerShell 403
decision: official JSON access path observed, but source registration blocked by challenge-cookie dependency and missing accepted adapter
```

Observed:

```text
Official IDX announcement pages rendered announcement lists.
The Nuxt announcement component uses /primary/NewsAnnouncement/GetAllAnnouncement.
The endpoint returned JSON with Items, ItemCount, PageSize, PageNumber, and PageCount for accepted bounded query shapes.
dateFrom/dateTo in YYYYMMDD format returned 200 JSON for a bounded date-window request.
Direct Node and PowerShell probes returned Cloudflare 403.
Fly/Elixir direct API/page-bootstrap probes returned Cloudflare 403 HTML.
Fly/Elixir cookie-mediated API retry returned 200 JSON, but that dependency is not accepted for source registration.
IDX challenge-cookie access decision recorded.
```

Decision:

```text
Do not register IDX as an rss_v1 source.
Do not treat the HTML page or Nuxt inline state as live source input.
Do not treat challenge-cookie-mediated API success as automatic source-registration approval.
Do not fetch attachment PDFs in the initial candidate.
Add a source only after a clean backend runtime path, bounded JSON adapter, query-shape policy, rate/cadence policy, and staging smoke pass.
```

### Vietnam HNX Issuer Disclosures

```text
authority: official Hanoi Stock Exchange surface
candidate URL: https://www.hnx.vn/3/vi_vn/thong-tin-cong-bo-tu-to-chuc-phat-hanh.rss
category: ASEAN/Vietnam issuer disclosures
quick result: 200 application/rss+xml
decision: inactive rss_v1 source candidate added; first manual staging live poll passed
```

Observed:

```text
The HNX information-disclosure page exposes issuer-disclosure sections.
The HNX RSS index lists the issuer-disclosure RSS channel.
The issuer-disclosure RSS endpoint returned RSS 2.0 XML with bounded issuer-disclosure item metadata.
The existing rss_v1 parser accepts the fixture sample.
The candidate remains active=false and fixture fallback is disabled for live smoke.
The first manual Fly staging smoke inserted 25 live records and the latest digest showed 6 HNX live items.
```

Decision:

```text
Do not activate the HNX Vietnam source yet.
Do not enable ASEAN scheduled live polling.
Do not fetch HNX detail pages or attachments in the initial candidate.
Prefer one more observation-window smoke before any activation or schedule discussion.
```

## Rejected For This Pass

```text
third-party SGX/Bursa/SET/IDX aggregators
company-specific investor-relations mirrors
HTML search/listing pages as rss_v1 input
token-protected API paths without accepted access contract
fixture fallback while claiming ASEAN live success
scheduled ASEAN polling
public poll UI
public Source Health UI
backend public JSON response-shape changes
JP live polling before issue #339 is resolved
```

## Acceptance Gate For Any ASEAN Source

Before an ASEAN source can be registered, it must pass:

```text
authority: official exchange/regulator or explicitly accepted third-party
endpoint: exact RSS, Atom, XML, JSON, or known API shape
http: stable 2xx from the intended runtime environment
parser: rss_v1 compatible or a bounded source-specific adapter exists
auth/access: required headers/token/session flow documented and allowed
rate limit: documented or conservatively bounded
fallback: metadata.fallback_to_fixture=false during staging smoke
source: fetch.mode=live during staging smoke
UI: ASEAN item renders in public GlobalPulse Pages
rollback: disabling source does not affect SEC, India NSE, EU, CN/TW, APAC fixture coverage
response_shape: public digest JSON response shape unchanged
```

## Next Step

```text
ASEAN source registration remains blocked.
The safest next ASEAN task is a focused SGX access-path review:
- inspect the official SGX announcements token flow in a browser/network session
- confirm whether SGX terms allow backend polling of the JSON announcements endpoint
- capture a bounded sample response shape if access is accepted
- decide whether a dedicated SGX JSON adapter is appropriate
```

If SGX, SET, or IDX access is not acceptable, continue ANZ access-path review rather than widening scope or using third-party aggregators by default.
