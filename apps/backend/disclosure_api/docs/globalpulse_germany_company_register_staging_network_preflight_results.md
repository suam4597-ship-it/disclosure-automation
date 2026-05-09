# GlobalPulse Germany Company Register Staging Network Preflight Results

This document records the staging-network preflight for the German Company Register capital-market information surface.

This is documentation-only. It does not add a source, parser, fixture, route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboard, alert, or scheduled polling.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_SUPPORT_PAGE_PASS
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_SEARCH_TOKEN_PASS
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_TOKENIZED_SEARCH_PASS
GERMANY_COMPANY_REGISTER_NEXT_PAYLOAD_MARKER_CHANGED
GERMANY_COMPANY_REGISTER_ISO_DATE_RANGE_QUERY_PASS
GERMANY_COMPANY_REGISTER_PUBLICATION_DETAIL_URL_ROUTE_PASS
GERMANY_COMPANY_REGISTER_DAILY_PAGINATION_OVER_CAP_CONFIRMED
GERMANY_COMPANY_REGISTER_MANUAL_SOURCE_REGISTERED_IN_FOLLOW_UP
GERMANY_COMPANY_REGISTER_SCHEDULED_POLLING_DISABLED
```

## Environment

```text
date: 2026-05-09
Fly app: globalpulse-backend-staging
Fly machine: 9080d12db6d338
Fly region: nrt
deployed image: registry.fly.io/globalpulse-backend-staging:deployment-01KR6GGP6M143CQ09SSVY7C6JA
official host: www.unternehmensregister.de
local Windows TCP 443: failed before this staging preflight
staging TCP/HTTP reachability: confirmed by curl from the Fly machine
```

The staging container does not include curl in the release image. Curl was installed ephemerally inside the remote shell session for this preflight only. That installation is not a repository, image, runtime, or deployment change.

## Official Support Page

```text
request: HEAD/GET https://www.unternehmensregister.de/en/search/capital-market-info
status: 200
content-type: text/html; charset=utf-8
x-middleware-rewrite: /en/search/CAPITAL_MARKET
session cookies: issued
observed body bytes: 570418
capital marker count: 2
issuer marker count: 2
fixture fallback: false
```

This confirms the official capital-market support page is reachable from the intended staging network.

## Search Token

```text
request: GET https://www.unternehmensregister.de/api/search-token
status: 200
content-type: text/plain;charset=UTF-8
observed JSON keys: token, expiresAt, status
observed response status field: 200
session: same cookie jar as the support-page request
fixture fallback: false
```

The token value was intentionally not recorded because it is ephemeral.

## Tokenized Search

```text
request: GET https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET&searchToken=<fresh-token>
status: 200
content-type: text/html; charset=utf-8
observed body bytes: 693558
session: same cookie jar as support page and token request
fixture fallback: false
```

Observed payload markers:

```text
elasticSearch marker count: 1
publicationDto marker count: 1
sourceDate marker count: 1
searchResults.elasticSearchDtos exact marker count: 0
```

Representative row fields observed in the embedded payload:

```text
sourceDate first values: 2009-02-20, 2009-02-12, 2009-02-02, 2009-01-14
later sourceDate values included: 2024-09-17, 2024-08-16, 2023-11-09, 2023-09-22
companyNameAtTimeOfPublication examples: "PERUNI" Holding GmbH; "Royalbeach" Spielwaren und Sportartikel Vertriebs GmbH; Exporo Berlin GmbH
publicationNavigationDto: present with previousPublicationId and nextPublicationId encrypted payload-like values
sourceDateFrom/sourceDateTo input names: present
```

## ISO Date-Range Query

```text
request: GET https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET&searchToken=<fresh-token>&sourceDateFrom=2024-09-01&sourceDateTo=2024-09-30
status: 200
content-type: text/html; charset=utf-8
observed body bytes: 731794
publication URL count on first page: 30
observed sourceDate values: 2024-09-06, 2024-09-11, 2024-09-17, 2024-09-18, 2024-09-20, 2024-09-23, 2024-09-25, 2024-09-30
query echoed in pagination links: sourceDateFrom=2024-09-01&sourceDateTo=2024-09-30
fixture fallback: false
```

Negative date-format probe:

```text
request: GET ...&sourceDateFrom=01.09.2024&sourceDateTo=30.09.2024
status: 200
observed body bytes: 549374
publication URL count: 0
decision: do not use dotted German date strings for the fetch contract
```

Daily bounded probe:

```text
request: GET ...&sourceDateFrom=2024-09-30&sourceDateTo=2024-09-30
status: 200
observed body bytes: 749008
publication URL count on first page: 30
observed first-page sourceDate values: 2024-09-30 only
observed page marker: Page 1 of 7
observed embedded drilldown: totalResults=188, totalPages=7, hasReachedResultsLimit=false, isRestrictedSearch=true
observed pagination offsets: from=0, from=30, from=60, from=90, from=120, from=180
page size: 30
fixture fallback: false
```

This proves the ISO `YYYY-MM-DD` date-range query contract, but it also proves a single source date can exceed one page. The follow-up manual candidate therefore records an explicit max_pages_per_poll cap and over_page_cap metadata, while duplicate handling and rate/captcha behavior remain blockers for scheduled-poll promotion.

## Publication Detail URL

```text
source: first /en/publication?payload=<encryptedPayload> link extracted from the tokenized search HTML
request: HEAD/GET https://www.unternehmensregister.de/en/publication?payload=<encryptedPayload>
searchToken required in URL: no
explicit cookie jar required for probe: no
status: 200
content-type: text/html; charset=utf-8
x-middleware-rewrite: /en/publication?payload=<encryptedPayload>
observed body bytes: 574142
sourceDate marker count: 1
fixture fallback: false
```

This proves a stable public detail route shape for canonical URLs:

```text
canonical URL template: https://www.unternehmensregister.de/en/publication?payload=<encryptedPayload>
external_id candidate: de-company-register:<digest of encryptedPayload>
```

PDF or XML download behavior is not proven in this pass. The first candidate should use the public publication detail URL as the canonical URL unless a separate download contract is proven.

## Interpretation

```text
Staging-network reachability is no longer the blocking item.
ISO sourceDateFrom/sourceDateTo query parameters are now proven.
The public /en/publication?payload=<encryptedPayload> detail route is now proven for canonical URLs.
The exact payload marker assumed by the first token-preflight note changed or is not present in the staging HTML.
The unfiltered tokenized search is not acceptable as a live polling source because the first observed sourceDate values are historical and the page includes mixed historical/newer dates.
Daily date windows can exceed one page, so the follow-up manual candidate uses a documented page cap and keeps full pagination/duplicate handling as scheduled-promotion blockers.
Publication detail URL behavior is proven, but PDF/XML download behavior is not.
```

## Registration Decision

```text
This preflight did not itself register a source, parser, or fixture; the follow-up candidate registers only an inactive/manual_staging_only source with a source-specific token preflight fetch adapter.
Do not treat the unfiltered tokenized search page as newest-first.
Do not rely on searchResults.elasticSearchDtos as a required exact marker without refreshing the parser contract.
Do not promote page-capped live polling without a documented pagination and rollback design.
Keep scheduled polling disabled.
```

## Next Step

```text
Run staging live poll smoke for the follow-up inactive/manual_staging_only candidate.
Record source health, live fetch metadata, max_pages_per_poll, over_page_cap, records_seen, records_inserted, fixture fallback=false, and digest visibility.
Optionally probe PDF/XML download routes, but do not require them for canonical URL formation if /en/publication?payload remains stable.
Keep scheduled EU polling disabled until over-cap pagination, duplicate-key behavior, rate/captcha behavior, and rollback are designed.
```
