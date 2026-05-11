# GlobalPulse HKEX Latest Listed Company Asset Scan

Date: 2026-05-11 KST

This document records a bounded scan of official HKEXnews latest listed-company information assets for the CN/TW live-source track.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_LATEST_LISTED_COMPANY_ASSET_SCAN_RECORDED
HKEX_HOME_LLCI_SURFACE_CONFIRMED
HKEX_LLCI_CATEGORY_JSON_CONFIRMED
HKEX_LATEST_SUBMISSIONS_JSON_CONFIRMED
HKEX_LOCAL_ERLANG_HTTPC_LLCI_JSON_FETCH_PASS
HKEX_MACHINE_READABLE_LATEST_ASSET_CANDIDATE_CONFIRMED
HKEX_SOURCE_REGISTRATION_STILL_BLOCKED
NO_HKEX_SOURCE_REGISTERED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Scope

The scan stayed on official HKEX/HKEXnews assets:

```text
HKEXnews Latest Listed Company Information shell
HKEXnews latestlistedcompanyinformation config.js
HKEXnews latestlistedcompanyinformation main.js
HKEXnews /ncms/script/eds/homecat_e.json
HKEXnews /ncms/script/eds/homecat0_e.json through homecat7_e.json
HKEXnews title-search static metadata JSON assets
```

It did not use third-party filing APIs, market-data aggregators, PDF attachments, detail documents, login-only routes, or browser challenge bypasses.

## Official Latest Listed Company Information Shell

Official shell:

```text
GET https://www.hkexnews.hk/homeLLCI.html
status: 200
content_type: text/html
length: 2425 bytes
```

The shell loads the official latest-listed-company-information assets:

```text
/ncms/eds/latestlistedcompanyinformation/config.js
/ncms/eds/latestlistedcompanyinformation/main.js
```

Interpretation:

```text
HKEXnews exposes a dedicated Latest Listed Company Information surface.
The shell is not a source by itself, but it points to official JavaScript and JSON assets.
```

## LLCI Config And Loader

Official config:

```text
GET https://www.hkexnews.hk/ncms/eds/latestlistedcompanyinformation/config.js
status: 200
content_type: text/javascript
length: 816 bytes
```

Relevant observed config values:

```text
LLCIConfig.JsonFileMimeType = application/json; charset=UTF-8
LLCIConfig.LLCIList = /ncms/script/eds/homecat_e.json
LLCIConfig.ShowSevenDays = SHOW: 7 DAYS
```

Official loader:

```text
GET https://www.hkexnews.hk/ncms/eds/latestlistedcompanyinformation/main.js
status: 200
content_type: text/javascript
length: 21302 bytes
```

Relevant observed loader behavior:

```text
LoadLLIJSONData(url, async) fetches JSON.
RefreshJson(url, async) fetches JSON.
LoadBoxListJsonData() fetches LLCIConfig.LLCIList.
CreateBoxContent(ContentJson, ...) derives /ncms/script/eds/<ContentJson>.
DisplayBoxContent(...) renders data.newsInfo.
GetBoxContentStr(...) reads sTxt, title, ext, size, webPath, relD, relM, relY, relTime, stock, dod, and dodPath.
```

Interpretation:

```text
The LLCI surface uses official JSON assets rather than only HTML table scraping.
The JavaScript contract identifies the JSON field family needed for a bounded parser design.
```

## Category JSON

Official category list:

```text
GET https://www.hkexnews.hk/ncms/script/eds/homecat_e.json
status: 200
content_type: application/json
length: 529 bytes
```

Observed categories:

```text
LATEST SUBMISSIONS -> homecat0_e.json
FINANCIAL STATEMENTS/ESG INFORMATION -> homecat1_e.json
IPO ALLOTMENT RESULTS -> homecat2_e.json
NOTICES OF GENERAL MEETINGS -> homecat3_e.json
PROSPECTUSES -> homecat4_e.json
RESULTS ANNOUNCEMENTS -> homecat5_e.json
RESULTS OF GENERAL MEETINGS -> homecat6_e.json
RESUMPTION / SUSPENSION / TRADING HALT -> homecat7_e.json
```

The category names and JSON paths came directly from the official JSON body.

## Latest Submissions JSON

Official latest-submissions JSON:

```text
GET https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
status: 200
content_type: application/json
length: 1940 bytes
newsInfo_count: 5
viewAllHyperlink: https://www1.hkexnews.hk/listedco/listconews/index/lci.html?lang=en
```

Observed first item markers on 2026-05-11 KST:

```text
relY: 2026
relM: 05
relD: 11
relTime: 12:23
title: OVERSEAS REGULATORY...
sTxt: Announcements and Notices - [Overseas Regulatory Announcement - Issue...]
ext: pdf
webPath: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051100197.pdf
stock: 00855 CHINA WATER
```

Interpretation:

```text
homecat0_e.json is a machine-readable latest-listed-company-information candidate.
The asset is bounded to a small list and exposes timestamp, stock code, issuer short name, title/category text, file extension, and document URL fields.
The first parser candidate should record metadata and announcement links only; it should not fetch PDF or detail document bodies.
```

## Other Category JSON Assets

All category JSON assets returned 200 application/json from the same official path family.

```text
homecat1_e.json: 5 items, Financial Statements/ESG Information
homecat2_e.json: 5 items, IPO Allotment Results
homecat3_e.json: 5 items, Notices of General Meetings
homecat4_e.json: 3 items, Prospectuses
homecat5_e.json: 5 items, Results Announcements
homecat6_e.json: 5 items, Results of General Meetings
homecat7_e.json: 5 items, Resumption / Suspension / Trading Halt
```

Decision:

```text
For a first HKEX candidate, prefer homecat0_e.json only.
Do not combine all category JSON assets into one source until dedupe, category mapping, and downstream digest diversity are designed.
```

## Title Search Static Metadata Assets

The prior title-search scan found official HTML results. This asset scan also confirmed title-search static metadata files:

```text
GET https://www1.hkexnews.hk/ncms/eds/titlesearch/config.js
status: 200
content_type: text/javascript
length: 3681 bytes
```

Relevant observed values:

```text
TitleSearchActionUrl = https://www1.hkexnews.hk/search/titlesearch.xhtml
StockSearchPartialUrl = https://www1.hkexnews.hk/search/partial.do?
StockSearchPrefixUrl = https://www1.hkexnews.hk/search/prefix.do?
TierOneUrl = /ncms/script/eds/tierone_e.json
TierTwoUrl = /ncms/script/eds/tiertwo_e.json
TierTwoGrpUrl = /ncms/script/eds/tiertwogrp_e.json
DocUrl = /ncms/script/eds/doc_e.json
ActiveStockUrl = /ncms/script/eds/activestock_sehk_e.json
SearchDocAllMaxMonthRange = 1
SearchDocSingleMaxMonthRange = 12
ViewMoreRecords = 1000
```

Static metadata probes:

```text
tierone_e.json: 200 application/json, 20 records
tiertwogrp_e.json: 200 application/json, 22 records
tiertwo_e.json: 200 application/json, 293 records
doc_e.json: 200 application/json, 17 records
activestock_sehk_e.json: 200 application/json, 18050 records
```

Interpretation:

```text
Title Search remains useful as a richer search/parser design input.
The first latest-list candidate should use the smaller LLCI homecat0_e.json asset before attempting title-search pagination or issuer enumeration.
```

## Local Erlang HTTP Probe

A local Erlang/Elixir `:httpc` probe fetched the LLCI JSON assets:

```text
runtime: Elixir 1.18.4
Erlang/OTP: 28
HTTP path: Erlang :httpc
target: https://www.hkexnews.hk/ncms/script/eds/homecat_e.json
status: 200
content_type: application/json
bytes: 529
has_latest_submissions: true

target: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
status: 200
content_type: application/json
bytes: 1940
has_news_info: true
has_stock_code: true
has_pdf_link: true
```

This is positive local runtime evidence. It is not a Fly staging release-eval pass and does not prove production polling readiness.

## Source Registration Decision

```text
Do not register an HKEX source from this docs-only scan.
Do not enable production scheduled polling.
Do not fetch HKEX PDFs, HTM attachments, detail pages, or document bodies in the first candidate.
Do not claim Fly staging live-poll success from local PowerShell or local Erlang success.
Do not merge HKEX into Taiwan MOPS or Mainland China buckets.
Do not treat any fixture fallback as live success.
```

Required before a source/parser PR:

```text
accepted source key and region mapping, likely hk / Hong Kong
bounded parser contract for homecat0_e.json newsInfo rows
reference-id strategy for webPath and/or rel timestamp plus stock code
attachment/detail-fetch exclusion in code and tests
fixture fallback disabled
source active=false
manual staging-only candidate status
Fly staging or application-runtime GET verification for homecat0_e.json
manual staging poll smoke with fetch.mode=live and metadata.fallback_to_fixture=false
public digest visibility smoke after staging poll
rollback plan that disables the source without affecting SEC, NSE, SET, HNX, HSX, or Taiwan MOPS
```

## Guardrails

```text
source registration not added
active=true not set
production scheduled polling not enabled
workflow schedule unchanged
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
no HKEX PDF/detail/attachment fetch
fixture fallback cannot be claimed as live success
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Draft an HKEX homecat0_e.json bounded parser/source contract while keeping source registration inactive.
2. Run a Fly/application-runtime probe against homecat0_e.json when Fly CLI/auth is available.
3. Add a bounded inactive HKEX JSON parser/source candidate only after the parser contract is accepted.
4. Keep CN/TW production scheduled polling disabled.
```
