# GlobalPulse Bursa Malaysia Company Announcements Access Path Review

Date: 2026-05-11 KST

This document records a focused follow-up review of Bursa Malaysia company announcements after SGX was confirmed as browser-accessible but blocked for source registration by policy and runtime review.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
BURSA_MALAYSIA_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
BURSA_MALAYSIA_ANNOUNCEMENTS_JSON_SHAPE_CAPTURED_BOUNDED
BURSA_MALAYSIA_SOURCE_REGISTRATION_BLOCKED_BY_CLOUDFLARE_RUNTIME_FETCH
ASEAN_SOURCE_REGISTRATION_STILL_BLOCKED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Surface

```text
official page: https://www.bursamalaysia.com/market_information/announcements/company_announcement
disclaimer page: https://www.bursamalaysia.com/disclaimer_company_announcement
page title: Company Announcements
category: Malaysia / ASEAN listed-company announcements
rendered row date observed: 11 May 2026
rendered row count observed on first page: 20
```

The browser-rendered page displayed a company-announcement table with:

```text
No.
Ann. Date
Co. Name
Title
```

Observed first rows included listed issuers such as CENTRAL GLOBAL BERHAD, ECO WORLD DEVELOPMENT GROUP BERHAD, ABF MALAYSIA BOND INDEX FUND, and TECHNA-X BERHAD.

## Browser Access Path

The public page uses a browser XHR endpoint:

```text
GET https://www.bursamalaysia.com/api/v1/announcements/search?ann_type=company&per_page=20&page=1
headers observed:
  Accept: application/json, text/javascript, */*; q=0.01
  X-Requested-With: XMLHttpRequest
  Referer: https://www.bursamalaysia.com/market_information/announcements/company_announcement
```

The browser response returned HTTP 200 JSON:

```text
recordsTotal: 2062604
recordsFiltered: 2062604
data rows: 20
```

The response embeds table-cell HTML strings instead of typed JSON objects. A parser would need to treat those rows as bounded HTML fragments and extract only table metadata.

Observed first row shape:

```text
row[0]: ordinal number
row[1]: announcement date HTML
row[2]: company profile anchor HTML
row[3]: announcement detail anchor HTML
```

Observed first detail link:

```text
https://www.bursamalaysia.com/market_information/announcements/company_announcement/announcement_details?ann_id=3664474
```

Do not fetch detail pages or attachments in an initial candidate. The safe parser boundary, if approved later, should stay on the search result table metadata only.

## Runtime Fetch Blocker

Observed request behavior:

```text
browser-rendered page: pass
browser XHR to /api/v1/announcements/search: 200
direct PowerShell page request: 403
direct PowerShell disclaimer request: 403
fresh Playwright API request to /api/v1/announcements/search: 403 Cloudflare challenge page
Playwright browser-context request after page load: 403 Cloudflare challenge page
```

Implication:

```text
The official browser endpoint and JSON/table shape are proven.
The current backend-style non-browser fetch path is not proven and appears blocked by Cloudflare challenge behavior.
Do not register Bursa Malaysia as a live source until the exact Fly/Elixir runtime fetch path is accepted and passes without challenge bypassing.
```

This is a stronger runtime blocker than SGX. SGX had a browser-compatible JSON token path that also worked from a fresh Playwright API context. Bursa Malaysia's API did not work from a fresh API context during this review.

## Disclaimer Surface

The Bursa disclaimer page states that company announcements are sent electronically on behalf of, or in relation to, companies and are provided on an "as is" basis. It also states that Bursa Malaysia acts as a passive conduit for circulation, publication, and dissemination, and does not verify or endorse the contents.

This confirms source authority as an official exchange announcement surface, but it does not solve the runtime access problem or grant a backend polling/redistribution contract.

## Source Registration Decision

Do not register a Bursa Malaysia source yet.

Current decision:

```text
source key proposal: my_bursa_company_announcements
parser/adapter proposal: bursa_malaysia_company_announcements_table_json_v1
registration status: blocked
blocking class: cloudflare_runtime_fetch_blocker + backend_runtime_fetch_probe
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## If Runtime Access Is Accepted Later

If Bursa runtime access becomes acceptable later, the first implementation should be bounded:

```text
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
endpoint: /api/v1/announcements/search
ann_type: company
page: 1 only
per_page: 20 or lower
detail/attachment fetch: disabled
stored fields: bounded list metadata only
fixture: redacted bounded JSON table rows only
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

Required validation before any parser/source PR:

```text
Fly/Elixir runtime fetch probe returns 2xx JSON without Cloudflare challenge HTML
parser rejects challenge pages and non-JSON responses
parser extracts only bounded row metadata
no detail pages or attachment documents are fetched
rate/cadence cap is documented
disclaimer/access result is recorded
```

## Guardrails

```text
Do not add Bursa as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not bypass Cloudflare or other anti-automation controls.
Do not fetch detail pages or issuer attachments in the initial candidate.
Do not claim Bursa live readiness from browser-only success.
Do not enable ASEAN scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party Bursa mirrors or aggregators by default.
```

## Allowed Next PRs

```text
1. Retry SET Thailand official company-news access-path review.
2. Retry IDX Indonesia official announcement access-path review.
3. Add a Bursa runtime compatibility probe only if an acceptable non-browser fetch path is identified.
4. Add a bounded inactive Bursa parser/source candidate only after runtime fetch and access gates pass.
```
