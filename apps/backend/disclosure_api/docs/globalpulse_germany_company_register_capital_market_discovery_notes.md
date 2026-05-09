# GlobalPulse Germany Company Register Capital Market Discovery Notes

This document records the follow-up discovery pass for the German Company Register capital-market information surface.

This discovery note is paired with a later inactive/manual_staging_only candidate implementation. It does not add a route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, dashboard, alert, or scheduled polling.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_OFFICIAL_CAPITAL_MARKET_SURFACE_CONFIRMED
GERMANY_COMPANY_REGISTER_SEARCH_TOKEN_ENDPOINT_CONFIRMED
GERMANY_COMPANY_REGISTER_SEARCH_RESULTS_HTML_FLIGHT_DATA_CONFIRMED
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_PREFLIGHT_CONFIRMED
GERMANY_COMPANY_REGISTER_CURRENT_PAYLOAD_MARKER_CHANGED
GERMANY_COMPANY_REGISTER_ISO_DATE_RANGE_QUERY_CONFIRMED
GERMANY_COMPANY_REGISTER_PUBLICATION_DETAIL_URL_ROUTE_CONFIRMED
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_FETCH_CONTRACT_RECORDED
GERMANY_COMPANY_REGISTER_STATIC_POLL_URL_NOT_USED
GERMANY_COMPANY_REGISTER_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
GERMANY_COMPANY_REGISTER_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_FETCH_ADAPTER_ADDED
```

## Official Surface

```text
owner: Unternehmensregister / Company Register
supporting URL: https://www.unternehmensregister.de/en/search/capital-market-info
German URL: https://www.unternehmensregister.de/de/suche/kapitalmarktinformationen
authority class: official German company-register capital-market information surface
observed HTTP: 200
observed content-type: text/html; charset=utf-8
```

Why this fits the product direction:

```text
The page is explicitly scoped to issuer messages to the Company Register.
The official surface covers capital-market disclosure classes such as insider information, managers' transactions, country of origin, voting-rights notifications, securities acquisition and transfer, prospectus notices, and other capital-market information.
This is not a central-bank, macro, parliament, or policy-news feed.
```

## Tokenized Search Flow

Observed token preflight:

```text
request: GET https://www.unternehmensregister.de/api/search-token
status: 200
content-type: text/plain;charset=UTF-8
observed JSON keys: token, expiresAt, status
```

Observed result page with token:

```text
request: GET https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET&searchToken=<token>
status: 200
content-type: text/html; charset=utf-8
latest staging-network observed length: 693558 bytes
observed title: Company Register - The central platform for company data
observed markers: elasticSearch, publicationDto, sourceDate
exact marker not present in latest staging HTML: searchResults.elasticSearchDtos
```

Observed result page without token:

```text
request: GET https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET
status: 200
content-type: text/html; charset=utf-8
observed length: 545459 bytes
observed markers: no searchResults payload
```

Representative embedded result shape:

```text
The embedded payload contains publicationDto-style entries with companyNameAtTimeOfPublication, sourceDate, and publicationNavigationDto fields.
The first observed publication row in the unfiltered capital-market query used sourceName=Elektronischer Bundesanzeiger, sourceDate=2009-02-20, title=Sachstand, publicationPart.id=21.
The latest Fly staging tokenized search did not include the exact searchResults.elasticSearchDtos marker, so parser registration must be based on the current payload shape.
The latest Fly staging tokenized search exposed sourceDateFrom and sourceDateTo input names; the accepted ISO date-range query contract was proven in the follow-up staging preflight.
```

## Staging Network Preflight

```text
result doc: globalpulse_germany_company_register_staging_network_preflight_results.md
environment: globalpulse-backend-staging Fly machine 9080d12db6d338, region nrt
support page: HTTP 200, text/html, x-middleware-rewrite=/en/search/CAPITAL_MARKET
search token: HTTP 200, text/plain;charset=UTF-8, JSON keys token/expiresAt/status
tokenized search: HTTP 200, text/html, 693558 bytes
fixture fallback: false
```

Follow-up date/detail evidence:

```text
ISO month query: sourceDateFrom=2024-09-01&sourceDateTo=2024-09-30 returned HTTP 200, 731794 bytes, first-page publication URLs=30, and September 2024 sourceDate rows.
dotted date query: sourceDateFrom=01.09.2024&sourceDateTo=30.09.2024 returned HTTP 200 but publication URLs=0.
ISO daily query: sourceDateFrom=2024-09-30&sourceDateTo=2024-09-30 returned HTTP 200, first-page publication URLs=30, Page 1 of 7, totalResults=188, totalPages=7, and from offsets in increments of 30.
publication detail route: /en/publication?payload=<encryptedPayload> returned HTTP 200 without searchToken in the URL and exposed sourceDate markers.
canonical URL template: https://www.unternehmensregister.de/en/publication?payload=<encryptedPayload>
```

## Registration Decision

```text
Inactive/manual_staging_only source de_company_register_capital_market_info is registered for staging smoke only.
Do not register the static search page as rss_v1.
Do not register the tokenized search URL as a static base_url because searchToken is ephemeral.
Do not treat the tokenless search URL as live success because it returns the shell without searchResults.
Do not register third-party German register APIs as official GlobalPulse sources without explicit approval.
```

## Blocking Items

```text
Scheduled polling still needs a promotion design; the manual candidate now uses a source-specific per-poll preflight token request.
The result payload is embedded in Next.js/React flight HTML, not returned as a clean JSON/CSV/XML feed, so the manual parser consumes a structured fan-out JSON envelope produced by the live adapter.
Publication detail URLs use /en/publication?payload=<encryptedPayload>; PDF/XML download URLs still need confirmation.
The unfiltered result order is not confirmed as newest-first; the manual candidate uses a static date-specific staging smoke window instead.
The current staging HTML does not include the earlier exact searchResults.elasticSearchDtos marker; the manual parser extracts the current escaped searchResults payload shape.
ISO sourceDateFrom/sourceDateTo is proven, but single-day result windows can exceed one page; manual staging records max_pages_per_poll=1 and over_page_cap metadata.
```

## Token Preflight Contract

```text
contract doc: globalpulse_germany_company_register_token_preflight_contract.md
live_fetch_strategy: germany_company_register_token_preflight_v1
parser_key: germany_company_register_capital_market_flight_v1
candidate source_key: de_company_register_capital_market_info
candidate registration: inactive/manual_staging_only registered and staging live smoke passed
reason scheduled promotion remains blocked: over-cap pagination, duplicate keys, rate/captcha behavior, and rollback still need a separate design
```

## Next Step

```text
Record follow-up staging evidence in globalpulse_germany_company_register_staging_live_poll_smoke_results.md.
Before any scheduled promotion, prove multi-page traversal, duplicate handling, rate limits, captcha/security-query behavior, and rollback behavior.
Keep scheduled EU polling disabled.
```
