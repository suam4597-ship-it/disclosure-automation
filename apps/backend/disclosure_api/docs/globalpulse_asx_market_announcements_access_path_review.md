# GlobalPulse ASX Market Announcements Access Path Review

Date: 2026-05-11 KST

This document records a focused ANZ follow-up review of Australian Securities Exchange market announcements after ASEAN access-path reviews were completed for SGX, Bursa Malaysia, SET Thailand, and IDX Indonesia.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
ASX_OFFICIAL_MARKET_ANNOUNCEMENTS_JSON_ACCESS_PATH_CONFIRMED
ASX_MARKITDIGITAL_ANNOUNCEMENTS_JSON_SHAPE_CAPTURED_BOUNDED
ASX_DIRECT_NODE_AND_POWERSHELL_FETCH_PASS
ASX_ACCESS_POLICY_DECISION_RECORDED
ASX_SOURCE_REGISTRATION_BLOCKED_UNTIL_WRITTEN_AUTHORITY_OR_APPROVED_INFORMATION_SERVICE_PATH
NZX_OFFICIAL_CONTINGENCY_HTML_SURFACE_CONFIRMED
NZX_MACHINE_READABLE_ENDPOINT_NOT_ACCEPTED_YET
ANZ_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed ASX Surfaces

```text
official market-announcements page: https://www.asx.com.au/markets/trade-our-cash-market/announcements
official today's-announcements page: https://www.asx.com.au/markets/trade-our-cash-market/todays-announcements
legacy search page: https://www.asx.com.au/asx/v2/statistics/announcements.do
page title observed: Announcements
rendered date observed: Monday, 11 May 2026
rendered count observed: 286 announcements, 88 price sensitive
```

The modern ASX announcements page rendered a table with:

```text
Date / Time
Code / Company Name
Price Sensitive
Headline / Doc Size
Type
```

Observed first rows included RYD, IOV, STM, SPD, SRJ, and other ASX-listed issuers.

## ASX JSON Access Path

The modern ASX page loads a MarkitDigital announcements app:

```text
manifest: https://content.markitcdn.com/asx.markitdigital.com/js/manifests/com_asx_markets_announcements.js
appclass: https://content.markitcdn.com/asx.markitdigital.com/js/appclasses/com_asx_markets_announcements.appclass.js
```

The app calls a JSON endpoint:

```text
GET https://asx.api.markitdigital.com/asx-research/1.0/markets/announcements?page=0&itemsPerPage=25&summaryCountsDate=2026-05-11&includeFacets=true
headers used in direct probe:
  Accept: application/json
  Origin: https://www.asx.com.au
  Referer: https://www.asx.com.au/markets/trade-our-cash-market/announcements
```

Direct runtime-style probes returned HTTP 200 JSON:

```text
PowerShell direct fetch: 200 application/json
Node fetch direct fetch: 200 application/json
Playwright browser network fetch: 200 application/json
```

Observed response shape:

```text
top-level keys: data
data keys: items, count, facets, summaryCounts
items returned on page 0: 25
count observed: 10000
facets observed: announcementTypes, industries
```

Observed first item shape:

```text
symbol: RYD
headline: April - Net Tangible Asset Backing
date: 2026-05-11T02:51:45.000Z
documentKey: 2924-03088781-2A1671448
fileSize: 189KB
isPriceSensitive: false
announcementTypes: Periodic Reports - Other, Net Tangible Asset Backing
companyInfo.displayName: RYDER CAPITAL LIMITED
```

The legacy `/asx/1/company/CBA/announcements` API shape that older examples reference returned `404 uri-not-found` in this review, so it should not be used for new work.

## Access Policy Gate

The ASX market-announcements page states that access to and use of information made available on the ASX website, including Market Announcements, is subject to ASX terms of use. The page also identifies market-data copyright restrictions.

Implication:

```text
The JSON endpoint is technically strong enough for a bounded adapter candidate.
Source registration is now blocked by globalpulse_asx_markitdigital_access_policy_decision.md.
Public-site access is not enough authority for GlobalPulse backend polling, storage, digest materialization, or redistribution.
Revisit only after written ASX authority or an approved ASX Information Services/Company News path exists.
```

## NZX Follow-Up Check

The official NZX contingency surface was rechecked:

```text
official page: https://announcements.nzx.com/
page title: NZX Market Announcements
quick result: 200 text/html
rendered note: official NZX-operated alternative access to market announcements
rendered row count statement: showing most recent 200 announcements
last updated observed: 11/05/2026 14:57 NZST
```

Observed first rows included CO2, LGF060, CDI, AFI, MKR, VNT, AGL, and other issuers.

No RSS, Atom, JSON, or XML endpoint was observed in the browser network pass. The page returned static HTML/table content plus CSS and images.

Decision:

```text
Do not register NZX as an rss_v1 source.
Do not treat the contingency HTML table as live source input unless a dedicated HTML adapter is explicitly accepted later.
Continue to prefer ASX as the first ANZ adapter candidate.
```

## Source Registration Decision

Do not register an ASX or NZX source in this PR.

Current ASX decision:

```text
source key proposal: au_asx_market_announcements
parser/adapter proposal: asx_markitdigital_announcements_json_v1
registration status: blocked
blocking class: written_authority_or_approved_information_service_path_required + bounded_adapter_required + rate_cadence_policy
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## If ASX Access Is Accepted Later

If ASX access is accepted later, the first implementation should be bounded:

```text
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
endpoint: /asx-research/1.0/markets/announcements
page: 0
itemsPerPage: 25 or lower
summaryCountsDate: explicit UTC/Australia date selected by adapter
includeFacets: true only if needed for bounded metadata
document fetch: disabled
stored fields: bounded list metadata only
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

Required validation before any parser/source PR:

```text
written authority or approved ASX Information Services/Company News path recorded
Fly/Elixir runtime probe returns 2xx JSON
parser rejects HTML, challenge pages, and non-JSON responses
parser extracts only bounded data.items metadata
documents/PDFs are not fetched in the initial candidate
rate/cadence cap is documented
manual staging smoke confirms fetch.mode=live and metadata.fallback_to_fixture=false
```

## Guardrails

```text
Do not add ASX as an rss_v1 source.
Do not use the removed legacy /asx/1/company/{code}/announcements endpoint.
Do not fetch ASX announcement documents/PDFs in the initial candidate.
Do not treat NZX contingency HTML as an rss_v1 source.
Do not enable ANZ scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party ASX/NZX mirrors or aggregators by default.
```

## Allowed Next PRs

```text
1. Add SET Fly/Elixir runtime compatibility probe.
2. Add a bounded inactive SET JSON parser/source candidate only if runtime fetch and access gates pass.
3. Add IDX Fly/Elixir runtime compatibility probe if SET remains blocked.
4. Revisit ASX only after written authority or approved ASX Information Services path exists.
```
