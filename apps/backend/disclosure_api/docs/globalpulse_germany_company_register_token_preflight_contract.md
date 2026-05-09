# GlobalPulse Germany Company Register Token Preflight Contract

This document records the manual-candidate fetch contract for the German Company Register capital-market information surface.

This contract is paired with an inactive/manual_staging_only source, a source-specific token preflight fetch adapter, a parser, and a fixture. It does not add a route, controller, migration, backend response-shape change, frontend shell change, frontend framework, poll UI, audit UI, public Source Health UI, dashboard, alert, or scheduled polling.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_OFFICIAL_CAPITAL_MARKET_SURFACE_RECONFIRMED
GERMANY_COMPANY_REGISTER_STAGING_NETWORK_REACHABILITY_CONFIRMED
GERMANY_COMPANY_REGISTER_SEARCH_SORT_RELEVANCE_NOT_NEWEST_CONFIRMED
GERMANY_COMPANY_REGISTER_TOKEN_PREFLIGHT_FETCH_CONTRACT_RECORDED
GERMANY_COMPANY_REGISTER_CURRENT_NEXT_PAYLOAD_MARKER_CHANGED
GERMANY_COMPANY_REGISTER_ISO_DATE_RANGE_QUERY_CONFIRMED
GERMANY_COMPANY_REGISTER_PUBLICATION_DETAIL_URL_ROUTE_CONFIRMED
GERMANY_COMPANY_REGISTER_PAGE_CAPPED_MANUAL_FETCH_CONTRACT_RECORDED
GERMANY_COMPANY_REGISTER_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PENDING
GERMANY_COMPANY_REGISTER_SCHEDULED_POLLING_DISABLED
```

## Official Scope

```text
owner: Unternehmensregister / Company Register
supporting URL: https://www.unternehmensregister.de/en/search/capital-market-info
search help URL: https://www.unternehmensregister.de/en/howto/search
contents help URL: https://www.unternehmensregister.de/en/howto/content
terms URL: https://www.unternehmensregister.de/i18n-doc/D061_UReg_nutz_0118_en.pdf
authority class: official German company-register capital-market information surface
target surface: capital-market information / issuer messages to the Company Register
```

Why this remains in scope:

```text
The official capital-market page is scoped to issuer messages to the Company Register.
The official search help lists capital-market information as a searchable section and includes notifications of publications under capital-market law, publications under the Securities Trading Act and Investment Act, takeover-law publications, exchange-admission ordinance publications, and other information made public under the Securities Trading Act.
The official contents page describes the Company Register as the central platform for company data and includes publications and other information made publicly available under the German Securities Trading Act.
This is not a central-bank, macro, parliament, or policy-news feed.
```

## Revalidation Notes

```text
date: 2026-05-09
official page review: Company Register capital-market page and help pages reviewed
local workspace DNS: www.unternehmensregister.de -> 128.65.211.50
local workspace TCP 443: failed from the current Windows workspace
local curl/Invoke-WebRequest live smoke: not accepted as a source failure or source success because the current workspace could not open TCP 443 to the official host
Fly staging support page/token/tokenized search: HTTP 200 confirmed from globalpulse-backend-staging
staging preflight doc: globalpulse_germany_company_register_staging_network_preflight_results.md
source registration decision: inactive/manual_staging_only source registered for staging smoke only; scheduled polling and batch promotion remain blocked
```

Important ordering constraint:

```text
The official search help describes Company Register search results as sorted by relevance and narrowed by company and publication data.
Therefore an unfiltered CAPITAL_MARKET result page must not be treated as a newest-first disclosure feed.
The manual candidate uses a bounded date-specific retrieval contract rather than unfiltered newest-first ordering.
```

Important search-access constraint:

```text
The official search help notes search-limit behavior around disclosures after their first publication period and describes later search as constrained by prescribed search criteria.
Candidate promotion must therefore avoid relying on unbounded historical search behavior as the live polling contract.
```

## Candidate Shape

Registered manual candidate identity:

```text
candidate source_key: de_company_register_capital_market_info
candidate display_name: Germany Company Register Capital Market Information
candidate parser_key: germany_company_register_capital_market_flight_v1
source_type: html
base_url: https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET
healthcheck_url: https://www.unternehmensregister.de/en/search/capital-market-info
active: false
candidate_status: manual_staging_only
scheduled polling: disabled
```

Registered manual candidate config:

```yaml
config:
  fixture_path: source_payloads/de_company_register_capital_market_info.json
  candidate_status: manual_staging_only
  live_source_contract: globalpulse_germany_company_register_token_preflight_contract.md
  max_items_per_poll: 25
  live_fetch_strategy: germany_company_register_token_preflight_v1
  disable_live_fixture_fallback: true
  support_url: https://www.unternehmensregister.de/en/search/capital-market-info
  token_url: https://www.unternehmensregister.de/api/search-token
  search_url_template: https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET&searchToken={token}&sourceDateFrom={source_date_from}&sourceDateTo={source_date_to}&from={from}
  source_date_from: "2024-09-30"
  source_date_to: "2024-09-30"
  page_size: 30
  max_pages_per_poll: 1
  live_timeout_ms: 30000
```

Do not promote this config to scheduled polling until over-cap pagination, duplicate handling, rate/captcha behavior, and rollback are designed and smoke-tested.

## Fetch Contract

Source-specific live fetch sequence:

```text
1. Start a fresh HTTP session with cookies enabled.
2. GET https://www.unternehmensregister.de/en/search/capital-market-info.
3. Require HTTP 200, text/html content type, and the capital-market/issuer-message scope markers.
4. GET https://www.unternehmensregister.de/api/search-token with the same session.
5. Require HTTP 200 and a token response containing token, expiresAt, and status.
6. Build the CAPITAL_MARKET search URL only from the freshly issued token.
7. Add ISO date-range parameters as sourceDateFrom=YYYY-MM-DD and sourceDateTo=YYYY-MM-DD.
8. GET the tokenized CAPITAL_MARKET search URL with the same session.
9. Require HTTP 200, text/html content type, and current embedded payload markers that include publicationDto/sourceDate/companyNameAtTimeOfPublication or equivalent row fields.
10. Use from offsets in increments of page_size and stop at max_pages_per_poll for the manual candidate.
11. Record total_pages, total_results, pages_fetched, records_seen, records_kept, and over_page_cap when a date window exceeds the page cap.
12. Parse only bounded publicationDto rows from the embedded result payload.
13. Reject tokenless search shells, login pages, captcha/security-query pages, unsupported content types, missing markers, empty unbounded searches, and fixture fallback.
```

Expected live fetch metadata:

```text
fetch.mode: live
fetch.strategy: germany_company_register_token_preflight_v1
fetch.status_code: 200
fetch.token_status_code: 200
fetch.search_status_code: 200
fetch.loaded: true
fetch.source_date_from: populated
fetch.source_date_to: populated
fetch.records_seen: >= 1
fetch.records_kept: >= 1
fetch.over_page_cap: recorded
fetch.fixture_fallback: false
```

Staging-network marker update:

```text
2026-05-09 Fly staging tokenized search returned HTTP 200 with elasticSearch, publicationDto, and sourceDate markers.
2026-05-09 Fly staging tokenized search did not include the exact searchResults.elasticSearchDtos marker.
The manual candidate parser is based on the current escaped embedded searchResults payload shape, not the earlier exact marker assumption.
```

Staging-network date/detail update:

```text
2026-05-09 Fly staging ISO query sourceDateFrom=2024-09-01&sourceDateTo=2024-09-30 returned HTTP 200, first-page publication URLs=30, and September 2024 sourceDate rows.
2026-05-09 Fly staging dotted date query sourceDateFrom=01.09.2024&sourceDateTo=30.09.2024 returned HTTP 200 but no publication URLs.
2026-05-09 Fly staging daily ISO query sourceDateFrom=2024-09-30&sourceDateTo=2024-09-30 returned HTTP 200, first-page publication URLs=30, Page 1 of 7, totalResults=188, totalPages=7, and from offsets in increments of 30.
2026-05-09 Fly staging publication detail route /en/publication?payload=<encryptedPayload> returned HTTP 200 without searchToken in the URL.
```

## Parser Contract

Required row fields before canonical insertion:

```text
publicationDto.companyNameAtTimeOfPublication or equivalent issuer/company name
publicationDto.sourceDate or equivalent publication date
publicationDto.title
publicationDto.publicationType or publicationDto.publicationCategory
publicationDto.publicationPart
publicationDto.sourceName
publicationDto.publicationNavigationDto or another proven stable navigation/detail payload
```

Canonical mapping:

```text
issuer: companyNameAtTimeOfPublication
title: title
published_at: sourceDate normalized to UTC date/time; if only a date exists, record a documented date-only normalization rule before registration
category: publicationType/publicationCategory/publicationPart label
summary: bounded text from publication type/category/sourceName/sourceDate
external_id: de-company-register:<digest of encryptedPayload>
url: https://www.unternehmensregister.de/en/publication?payload=<encryptedPayload>
```

Parser rejection rules:

```text
reject if the payload lacks the current embedded publication result payload markers
reject if the payload lacks publicationDto rows
reject if sourceDate is missing
reject if company name and title are both missing
reject if only a tokenless search shell is present
reject if a captcha/security-query or login marker is present
reject if the only available URL includes an expired searchToken
```

## Blocking Items

```text
stable detail URL: resolved for /en/publication?payload=<encryptedPayload>
PDF/XML download URL: unresolved
publication date/time normalization: resolved for manual candidate as UTC midnight for date-only rows
date-range query parameters: resolved as sourceDateFrom/sourceDateTo with ISO YYYY-MM-DD values
pagination cap and over-cap behavior: resolved for manual candidate as max_pages_per_poll=1 with over_page_cap metadata; unresolved for scheduled-poll promotion
newest-first ordering: unresolved; date-specific retrieval is proven but can span multiple pages
parser approach for React/Next flight payload: resolved for manual candidate using the current escaped searchResults envelope
local workspace reachability: unresolved after the current workspace TCP 443 failure
Fly staging reachability: confirmed for support page, token endpoint, and tokenized search
rate-limit behavior: unresolved
captcha/security-query behavior: unresolved
```

## Required Evidence

```text
live HTTP 200 for the official capital-market support page from the intended staging environment: satisfied on 2026-05-09
live HTTP 200 for /api/search-token from the intended staging environment: satisfied on 2026-05-09
live HTTP 200 for a tokenized CAPITAL_MARKET search from the intended staging environment: satisfied on 2026-05-09
tokenized search includes current embedded publication result markers and publicationDto rows: satisfied on 2026-05-09
tokenless search is proven to be rejected by the parser/fetch adapter: satisfied by requiring token preflight envelope strategy
date-range parameters produce bounded results for the target polling window: ISO sourceDateFrom/sourceDateTo satisfied on 2026-05-09
ordering is proven newest-first, or a date-specific visibility contract is recorded: manual date-specific contract recorded with page-cap/over-cap metadata; scheduled promotion still blocked
stable canonical URL contract is proven without retaining an expired searchToken: /en/publication?payload satisfied on 2026-05-09
fixture includes tokenized search result with at least two rows: satisfied by source_payloads/de_company_register_capital_market_info.json
local parser smoke proves records >= 1 and first record has issuer/title/url/published_at: satisfied with 3 fixture records in candidate PR validation
staging live poll smoke proves records_seen >= 1, records_inserted >= 1, fetch.mode=live, fixture fallback=false, and digest visibility behavior
```

## Registration Decision

```text
Register only the inactive/manual_staging_only source in this pass.
Do not register the static capital-market search page as rss_v1.
Do not register a tokenized URL with a hard-coded searchToken.
Do not treat tokenless HTML shell fetches as live success.
Do not require PDF/XML download URLs for canonical records while the public /en/publication?payload route remains stable.
Do not use third-party German register APIs as official GlobalPulse sources without explicit approval.
```

## Next Step

```text
Deploy the inactive/manual_staging_only candidate to Fly staging and run live poll smoke.
Record source health, live fetch metadata, records_seen, records_inserted, canonical item count, fixture fallback=false, and digest visibility.
Keep over-cap pagination, duplicate handling, rate/captcha behavior, and rollback as blockers for any scheduled-poll promotion.
Keep EU scheduled polling disabled.
```
