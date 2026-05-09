# GlobalPulse Germany Company Register Capital Market Discovery Notes

This document records the follow-up discovery pass for the German Company Register capital-market information surface.

This is documentation-only. It does not add a source, parser, fixture, route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboard, alert, or scheduled polling.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_OFFICIAL_CAPITAL_MARKET_SURFACE_CONFIRMED
GERMANY_COMPANY_REGISTER_SEARCH_TOKEN_ENDPOINT_CONFIRMED
GERMANY_COMPANY_REGISTER_SEARCH_RESULTS_HTML_FLIGHT_DATA_CONFIRMED
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_PREFLIGHT_CONFIRMED
GERMANY_COMPANY_REGISTER_CURRENT_PAYLOAD_MARKER_CHANGED
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_FETCH_CONTRACT_RECORDED
GERMANY_COMPANY_REGISTER_STATIC_POLL_URL_NOT_CONFIRMED
GERMANY_COMPANY_REGISTER_SOURCE_REGISTRATION_BLOCKED
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_OR_STABLE_JSON_ENDPOINT_REQUIRED
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
The latest Fly staging tokenized search exposed sourceDateFrom and sourceDateTo input names, but the actual accepted date-range query contract is not yet proven.
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

## Registration Decision

```text
No source is registered.
Do not register the static search page as rss_v1.
Do not register the tokenized search URL as a static base_url because searchToken is ephemeral.
Do not treat the tokenless search URL as live success because it returns the shell without searchResults.
Do not register third-party German register APIs as official GlobalPulse sources without explicit approval.
```

## Blocking Items

```text
Current source live fetch supports a static base_url plus static headers/body, not a per-poll preflight token request.
The result payload is embedded in Next.js/React flight HTML, not returned as a clean JSON/CSV/XML feed.
Publication detail/download URLs appear to depend on encryptedPayload-style values, so a stable detail URL contract still needs confirmation.
The unfiltered result order is not yet confirmed as newest-first; observed page 1 contained older rows, so date/sort parameters must be proven before candidate registration.
The current staging HTML does not include the earlier exact searchResults.elasticSearchDtos marker, so parser markers need a refreshed contract before implementation.
```

## Token Preflight Contract

```text
contract doc: globalpulse_germany_company_register_token_preflight_contract.md
future live_fetch_strategy: germany_company_register_token_preflight_v1
future parser_key: germany_company_register_capital_market_flight_v1
future candidate source_key: de_company_register_capital_market_info
candidate registration: still blocked
reason: stable detail URL, date-range parameters, newest-first or bounded date-specific ordering, current React/Next payload parser shape, and captcha/rate-limit behavior still need evidence
```

## Next Step

```text
Use the staging-network preflight result to continue with date-range submission and detail/download navigation discovery.
Before candidate registration, prove date range, sort order, stable detail URL, page size, rate limits, fixture shape, parser validation markers, duplicate keys, and rollback behavior.
Keep scheduled EU polling disabled.
```
