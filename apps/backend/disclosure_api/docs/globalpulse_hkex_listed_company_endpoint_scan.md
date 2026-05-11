# GlobalPulse HKEX Listed Company Endpoint Scan

Date: 2026-05-11 KST

This document records a bounded scan of official HKEXnews listed-company publication surfaces for the CN/TW live-source track.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_LISTED_COMPANY_ENDPOINT_SCAN_RECORDED
HKEXNEWS_OFFICIAL_LISTED_COMPANY_PUBLICATION_SURFACE_CONFIRMED
HKEX_TITLE_SEARCH_HTML_RESULTS_CONFIRMED
HKEX_SIMPLE_SEARCH_SURFACE_CONFIRMED
HKEX_LOCAL_ELIXIR_RUNTIME_PROBE_PASS
HKEX_LATEST_LISTED_COMPANY_JSON_ASSET_CONFIRMED
HKEX_BACKEND_COMPATIBLE_SOURCE_CONTRACT_PENDING
HKEX_SOURCE_REGISTRATION_BLOCKED
NO_CNTW_SOURCE_REGISTERED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Scope

The scan stayed on official HKEX/HKEXnews surfaces:

```text
HKEX investor FAQ for listed company information publication
HKEXnews Listed Company Information Title Search
HKEXnews Listed Company Information Simple Search / homepage surface
HKEXnews content search explanatory surface
```

It did not use third-party filing APIs or market-data aggregators.

## Official Authority Surface

Official HKEX investor guidance identifies HKEXnews as the publication surface for listed-company documents submitted through HKEX's e-submission system.

Relevant official surfaces reviewed:

```text
HKEX FAQ:
https://www.hkex.com.hk/Global/Exchange/FAQ/Getting-Started?sc_lang=en

HKEXnews Title Search:
https://www1.hkexnews.hk/search/titlesearch.xhtml

HKEXnews simple search homepage:
https://www3.hkexnews.hk/listedco/listconews/simplesearch/simplesearch_main.aspx

HKEXnews content search:
https://www.hkexnews.hk/homelcicontentsearch.html
```

## Title Search Probe

Bounded stock-specific query:

```text
GET https://www1.hkexnews.hk/search/titlesearch.xhtml?category=0&market=SEHK&stockId=268
```

Observed with web fetch:

```text
status: 200
content_type: text/html
title: Listed Company Information Title Search
total records found: 868
first visible row release time: 25/03/2026 18:29
first visible row stock code: 00154
first visible row stock short name: BE ENVIRONMENT
first visible row document category: Announcements and Notices - Final Results
first visible row document link: PDF attachment
```

Observed with local PowerShell:

```text
status: 200
content_type: text/html;charset=UTF-8
length: 120709 bytes
total records found: 877
latest visible row release time: 04/05/2026 16:31
latest visible row stock code: 00154
latest visible row stock short name: BE ENVIRONMENT
latest visible row document category: Monthly Returns
```

Observed with local curl HEAD:

```text
status: 503 Service Unavailable
server: AkamaiGHost
content_type: text/html
```

Interpretation:

```text
HKEXnews title-search HTML is a real official issuer-publication surface.
The route can return bounded issuer rows through PowerShell/browser-style GET.
The surface is HTML, not a confirmed JSON/RSS feed.
The curl HEAD 503 means backend/runtime compatibility still needs a dedicated probe before source registration.
```

## Broad Title Search Probe

Bounded all-market title-search URL:

```text
GET https://www1.hkexnews.hk/search/titlesearch.xhtml?category=0&lang=EN&market=SEHK
```

Observed locally:

```text
status: 200
content_type: text/html;charset=UTF-8
length: 12392 bytes
stockId: -1
total records found: 0
result: no matches without a concrete query/search state
```

Interpretation:

```text
The title-search endpoint is not enough by itself as a latest-all feed.
A source candidate would need an accepted query contract, not just the endpoint root.
```

## Simple Search And Content Search Surface

Simple search homepage:

```text
GET https://www3.hkexnews.hk/listedco/listconews/simplesearch/simplesearch_main.aspx
PowerShell result: 200 text/html, 8977 bytes
curl HEAD result: 503 Service Unavailable from AkamaiGHost
```

The returned homepage shell describes the site as a way to find regulatory announcements and public disclosures of HKEX listed companies. It includes the Listed Company Information search entry point but does not provide a direct machine-readable feed in this probe.

Content search page:

```text
GET https://www.hkexnews.hk/homelcicontentsearch.html
PowerShell result: 200 text/html, 11545 bytes
```

The page points users to Title Search for listed company information and to Simple Search for recent listed company documents. This supports the authority of the HKEXnews surface but does not create a direct feed contract.

## Decision

```text
HKEX is a strong official CN/TW/HK listed-company disclosure candidate.
Do not register an HKEX source from this scan.
Do not parse PDF attachments in the first candidate.
Do not rely on third-party HK filing APIs.
Do not claim backend readiness from PowerShell/browser HTML success alone.
```

## Local Elixir Runtime Follow-Up

A local Erlang/Elixir `:httpc` probe later fetched the same bounded title-search URL successfully:

```text
record: globalpulse_hkex_local_elixir_runtime_probe_results.md
runtime: Elixir 1.18.4 / Erlang OTP 28
status: 200
content_type: text/html;charset=UTF-8
bytes: 120707
total_records: 877
issuer row markers: present
PDF link marker: present
```

This is positive local runtime evidence, but it is not a Fly staging release-eval pass. Source registration remains blocked until the Fly/application runtime path and query contract are accepted.

## Latest Listed Company Asset Follow-Up

A later official-asset scan confirmed that the HKEXnews Latest Listed Company Information shell points to official JSON assets:

```text
record: globalpulse_hkex_latest_listed_company_asset_scan.md
shell: https://www.hkexnews.hk/homeLLCI.html
config: https://www.hkexnews.hk/ncms/eds/latestlistedcompanyinformation/config.js
category list: https://www.hkexnews.hk/ncms/script/eds/homecat_e.json
latest submissions: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
```

Observed latest-submissions asset:

```text
status: 200
content_type: application/json
newsInfo_count: 5
viewAllHyperlink: https://www1.hkexnews.hk/listedco/listconews/index/lci.html?lang=en
local Erlang :httpc fetch: pass
```

Interpretation:

```text
HKEX now has a machine-readable latest-listed-company-information asset candidate.
The preferred next candidate is a bounded homecat0_e.json parser/source contract, not title-search pagination or PDF parsing.
Source registration remains blocked until a bounded parser/source contract and Fly/application-runtime path are accepted.
```

Required before an HKEX source PR:

```text
accepted source contract for latest listed-company documents
confirmed backend-compatible GET from Fly staging or application HTTP runtime for homecat0_e.json
parser decision: bounded JSON parser for homecat0_e.json newsInfo rows
source-level cap, date window, and pagination limits
fixture fallback disabled
source active=false
manual staging-only candidate status
no attachment/detail fetch in first candidate
terms/access-policy review for backend polling and downstream display
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
fixture fallback cannot be claimed as live success
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Run a Fly/application-runtime probe against the bounded HKEX title-search URL.
2. Draft a bounded parser/source contract for the official HKEX homecat0_e.json latest-submissions asset.
3. Add a bounded inactive HKEX parser/source candidate only after backend compatibility and parser shape are accepted.
4. Keep CN/TW production scheduled polling disabled.
```
