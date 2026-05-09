# GlobalPulse Prague PSE Multi-ISIN Source Design

This document records the design gate for the Prague Stock Exchange issuer-news and issuer-report JSON surfaces.

This is documentation-only. It does not add a source, parser, fixture, route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboard, alert, or scheduled polling.

## Conclusion

```text
PRAGUE_PSE_OFFICIAL_JSON_SURFACES_CONFIRMED
PRAGUE_PSE_ISSUER_UNIVERSE_SURFACE_CONFIRMED
PRAGUE_PSE_MULTI_ISIN_FANOUT_CONTRACT_RECORDED
PRAGUE_PSE_STATIC_SINGLE_URL_SOURCE_BLOCKED
PRAGUE_PSE_SOURCE_REGISTRATION_DEFERRED
PRAGUE_PSE_SCHEDULED_POLLING_DISABLED
```

## Official Surfaces

Issuer universe pages:

```text
prime market: https://www.pse.cz/en/market-data/shares/prime-market
standard market: https://www.pse.cz/en/market-data/shares/standard-market
start market: https://www.pse.cz/en/market-data/shares/start-market
free market: https://www.pse.cz/en/market-data/shares/free-market
observed HTTP: 200 for all four pages
observed content-type: text/html; charset=utf-8
observed ISIN detail-link count: 63 unique ISINs
observed by market: prime=12, standard=8, start=11, free=32
```

Issuer-specific JSON surfaces:

```text
issuer news URL pattern: https://www.pse.cz/api/news?lang=en&type=pse&page=1&homepage=0&searchKey=&dateFrom=&dateTo=&isin=<ISIN>
issuer reports URL pattern: https://www.pse.cz/api/file-reports?isin=<ISIN>&order=year-desc&lang=en
observed HTTP: 200 for sampled ISINs
observed content-type: application/json; charset=utf-8
```

## Sample Observations

```text
sample ISIN: CZ0005112300
issuer news status: 200
issuer news rows: 10
strict ISIN-matching news rows: 8
first strict news: 5979 | Cancellation of accelerated book-building of CEZ shares | 2022-02-25 08:16:33
issuer reports status: 200
issuer reports first year: 2025
issuer reports first rows: Annual financial report, Preliminary financial results, Financial report for Q3
```

```text
sample ISIN: NL0010391108
issuer news status: 200
issuer news rows: 6
strict ISIN-matching news rows: 6
first strict news: 5236 | Results of Photon Energy Share Offering | 2021-06-25 07:01:13
issuer reports status: 200
issuer reports years: 2025, 2024, 2023, 2022, 2021
issuer reports rows: 22
```

## Why A Static Source Is Blocked

```text
The global PSE news endpoint is not a clean all-issuer disclosure feed because it includes broad exchange/index/trading notices and rows with isin=null.
The issuer news endpoint is official and bounded, but it requires an isin parameter.
The issuer reports endpoint is official and bounded, but it requires an isin parameter.
The file-reports endpoint without an ISIN returned 404 in earlier discovery, and an empty isin returned 500.
Current source live fetch is static base_url oriented and does not have a first-class fan-out contract.
```

## Proposed Fetch Contract

```text
source class: multi_isin_fanout
candidate source key: cz_pse_issuer_disclosures_multi_isin
candidate status: manual_staging_only only
active: false
scheduled polling: disabled
```

First implementation slice:

```text
implemented source key: cz_pse_issuer_news_multi_isin
implemented parser key: pse_multi_isin_issuer_news_json_v1
scope: issuer-news-only fan-out over official share-market ISIN universe
reports: deferred until precise report publication-date semantics are confirmed
```

Fan-out sequence:

```text
1. Fetch the four official issuer universe pages.
2. Extract unique /en/detail/<ISIN> links.
3. Normalize ISIN to uppercase.
4. Apply a deterministic market/name order from the universe pages.
5. Cap the per-poll issuer set before API fan-out.
6. Fetch issuer news with type=pse for each selected ISIN.
7. Drop news rows where row.isin is null or where the comma-separated row.isin list does not include the query ISIN.
8. Fetch issuer reports for each selected ISIN only after deciding how to model report dates.
9. Merge, dedupe, sort, and cap records before canonical insertion.
```

Initial manual staging caps:

```text
max_issuers_per_poll: 10
max_news_items_per_issuer: 5
max_report_items_per_issuer: 3
max_items_per_poll: 25
request_timeout_ms: 30000
per_request_delay_ms: 250
```

Promotion caps after staging evidence:

```text
max_issuers_per_poll: 25
max_items_per_poll: 50
scheduled polling: still disabled until EU batch promotion design
```

## Parser Contract

Issuer universe parser:

```text
input: HTML from the four official share-market pages
required markers: /en/market-data/shares/, /en/detail/<ISIN>
output: market, isin, detail_url
reject if no /en/detail/<ISIN> links are found
```

Issuer news parser:

```text
input: JSON from /api/news?type=pse&isin=<ISIN>
required markers: data[]
required row fields after filtering: id, title, publishedAt, slug or id, isin containing query ISIN
published_at: publishedAt parsed as Prague-local or UTC-normalized timestamp after timezone decision
external_id: pse-news:<query_isin>:<id>
url: https://www.pse.cz/en/news/<slug> when slug exists; otherwise issuer detail URL
summary: bounded text from content stripped to plain text, plus source type PSE and query ISIN
drop: CTK rows, isin=null rows, rows whose comma-separated isin does not include query ISIN
```

Issuer reports parser:

```text
input: JSON from /api/file-reports?isin=<ISIN>&order=year-desc&lang=en
required markers: result.data
accepted shapes: year-keyed object with row arrays, or empty array
row fields: uuid, label, ref/path, extension, size
external_id: pse-report:<query_isin>:<uuid>
url: https://ftp.pse.cz + ref when ref/path starts with /Issuers.dta/
published_at: blocked until exact report publication date is confirmed; do not synthesize from year alone for live canonical rows
```

## Deduplication

```text
News duplicate key: cz_pse_issuer_news:<query_isin>:<id>
Report duplicate key: cz_pse_issuer_report:<query_isin>:<uuid>
Rows linked to multiple ISINs may produce one canonical row per query ISIN only if the row's comma-separated isin includes that ISIN.
Before scheduled promotion, confirm whether multi-ISIN news rows should collapse to one story group across ISINs or remain issuer-scoped.
```

## Rollback

```text
Keep the source active=false.
Keep candidate_status=manual_staging_only.
Disable scheduled polling.
If any fan-out request fails during manual smoke, return a bounded error and do not fall back to fixture as live success.
If issuer universe extraction returns zero ISINs, fail the poll rather than polling a stale cached universe.
If report published_at remains unresolved, register only issuer news first or keep reports fixture-only until a date contract exists.
```

## Required Evidence Before Candidate Registration

```text
official issuer universe fixture with at least one ISIN from each market
issuer news fixture with one strict ISIN-matching row and one isin=null row to prove filtering
issuer reports fixture with year-keyed object rows and one empty-array response fixture
local parser smoke: universe records >= 1, strict news records >= 1, reports parser handles empty response
live HTTP 200 for all universe pages
live HTTP 200 for sampled issuer news and reports endpoints
first news record has issuer/title/url/published_at
report records are not canonicalized until a precise published_at contract is confirmed
```

## Next Step

```text
Validate the issuer-news-only source-specific fetch adapter locally, then deploy to Fly staging and record a live poll smoke result.
Local fixture and live aggregate parser smoke passed for the issuer-news-only implementation slice.
Keep reports deferred until report publication dates are confirmed.
Do not register the HTML root, global PSE news endpoint, or per-issuer endpoints as standalone rss_v1 sources.
Keep EU scheduled polling disabled.
```
