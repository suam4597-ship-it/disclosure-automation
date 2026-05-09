# GlobalPulse Germany Company Register Staging Network Preflight Results

This document records the staging-network preflight for the German Company Register capital-market information surface.

This is documentation-only. It does not add a source, parser, fixture, route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboard, alert, or scheduled polling.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_SUPPORT_PAGE_PASS
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_SEARCH_TOKEN_PASS
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_TOKENIZED_SEARCH_PASS
GERMANY_COMPANY_REGISTER_NEXT_PAYLOAD_MARKER_CHANGED
GERMANY_COMPANY_REGISTER_DATE_RANGE_CONTRACT_STILL_BLOCKED
GERMANY_COMPANY_REGISTER_DETAIL_URL_CONTRACT_STILL_BLOCKED
GERMANY_COMPANY_REGISTER_SOURCE_REGISTRATION_BLOCKED
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

## Interpretation

```text
Staging-network reachability is no longer the blocking item.
The exact payload marker assumed by the first token-preflight note changed or is not present in the staging HTML.
The unfiltered tokenized search is not acceptable as a live polling source because the first observed sourceDate values are historical and the page includes mixed historical/newer dates.
The presence of sourceDateFrom/sourceDateTo inputs is useful but does not prove the accepted query-parameter contract.
publicationNavigationDto exposes previous/next encrypted payload-like values, but no stable canonical detail or PDF URL was proven.
```

## Registration Decision

```text
Do not register a source in this pass.
Do not add a parser in this pass.
Do not add a fixture in this pass.
Do not treat the unfiltered tokenized search page as newest-first.
Do not rely on searchResults.elasticSearchDtos as a required exact marker without refreshing the parser contract.
Do not canonicalize rows until a stable detail/PDF URL is proven.
Keep scheduled polling disabled.
```

## Next Step

```text
Use a browser/network or staging-network session to submit the capital-market form with sourceDateFrom/sourceDateTo and any sort/page controls.
Record the exact accepted date-range query/body contract.
Prove whether the bounded result order is newest-first or whether a date-specific retrieval contract is required.
Follow a publicationNavigationDto/encrypted-payload action to identify a stable public detail or PDF URL.
After those items are proven, add only an inactive/manual_staging_only candidate source with a source-specific token preflight fetch adapter.
```
